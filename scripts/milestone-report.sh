#!/usr/bin/env bash
# milestone-report.sh : run every check and save results + diff for review.
# Usage: scripts/milestone-report.sh <label e.g. M3> [base-branch=main]
# Output: .private/reports/<label>/<timestamp>/   (gitignored)
# Env:    GRADLE_TEST_TASK  Kotlin JVM test task (default ":app:testDebugUnitTest")
# Does not use -e on purpose: we want every step's result, then a final exit code.
set -uo pipefail

LABEL="${1:?usage: milestone-report.sh <label e.g. M3> [base-branch]}"
BASE="${2:-main}"
ROOT="$(git rev-parse --show-toplevel)"
cd "$ROOT"

TS="$(date +%Y%m%d-%H%M%S)"
REPORTS="$ROOT/.private/reports/$LABEL"
OUT="$REPORTS/$TS"
mkdir -p "$OUT"
FAIL=0
STEPS=()

run_step() { # run_step <name> <logfile> <cmd...>
  local name="$1" log="$2"; shift 2
  echo ">>> $name"
  ( "$@" ) >"$OUT/$log" 2>&1
  local rc=$?
  if [ $rc -eq 0 ]; then STEPS+=("PASS  $name")
  else STEPS+=("FAIL  $name (exit $rc, see $log)"); FAIL=1; fi
}
skip_step() { STEPS+=("SKIP  $1 ($2)"); }

# ---- environment fingerprint ------------------------------------------------
{
  echo "label:   $LABEL"
  echo "time:    $(date -Is)"
  echo "branch:  $(git rev-parse --abbrev-ref HEAD 2>/dev/null)"
  echo "commit:  $(git rev-parse HEAD 2>/dev/null)"
  echo "dirty:   $(git status --porcelain | wc -l) changed paths"
  echo "node:    $(node --version 2>/dev/null || echo n/a)"
  echo "java:    $(java -version 2>&1 | head -1 || true)"
  echo "python:  $(python3 --version 2>/dev/null || echo n/a)"
} > "$OUT/env.txt"

# ---- checks -----------------------------------------------------------------
if [ -f scripts/check-structure.sh ]; then
  run_step "structure check" structure.txt bash scripts/check-structure.sh
else skip_step "structure check" "scripts/check-structure.sh missing"; fi

if [ -f app/package.json ]; then
  if grep -q '"lint"' app/package.json; then
    run_step "lint" lint.txt npm --prefix app run lint --silent
  else skip_step "lint" "no lint script"; fi

  if grep -q '"typecheck"' app/package.json; then
    run_step "typecheck" typecheck.txt npm --prefix app run typecheck --silent
  else skip_step "typecheck" "no typecheck script"; fi

  if grep -q '"test"' app/package.json; then
    run_step "jest (unit+integration+component)" jest.txt \
      npm --prefix app test -- --ci --coverage \
        --coverageDirectory="$OUT/coverage" \
        --coverageReporters=json-summary --coverageReporters=text-summary \
        --json --outputFile="$OUT/jest.json"
  else skip_step "jest" "no test script"; fi
else skip_step "app checks" "app/package.json missing"; fi

if [ -d data/etl/tests ] && [ -n "$(find data/etl/tests -name 'test_*.py' 2>/dev/null)" ]; then
  run_step "pytest data/etl" pytest-etl.txt \
    bash -c "cd data/etl && python3 -m pytest -q --junitxml='$OUT/pytest-etl.xml'"
else skip_step "pytest data/etl" "no tests yet"; fi

if [ -d eval/tests ] && [ -n "$(find eval/tests -name 'test_*.py' 2>/dev/null)" ]; then
  run_step "pytest eval" pytest-eval.txt \
    bash -c "cd eval && python3 -m pytest -q --junitxml='$OUT/pytest-eval.xml'"
else skip_step "pytest eval" "no tests yet"; fi

if [ -f app/android/gradlew ]; then
  run_step "kotlin unit tests" gradle-test.txt \
    bash -c "cd app/android && bash ./gradlew ${GRADLE_TEST_TASK:-:app:testDebugUnitTest} --console=plain"
  mkdir -p "$OUT/kotlin-test-results"
  find app/android -path '*build/test-results*' -name '*.xml' \
    -exec cp {} "$OUT/kotlin-test-results/" \; 2>/dev/null || true
else skip_step "kotlin unit tests" "app/android not initialized yet"; fi

# ---- diff + commits ---------------------------------------------------------
if git rev-parse --verify -q "$BASE" >/dev/null; then
  git diff "$BASE"...HEAD            > "$OUT/diff.patch"
  git diff --stat "$BASE"...HEAD     > "$OUT/diffstat.txt"
  git diff --name-status "$BASE"...HEAD > "$OUT/files-changed.txt"
  git log --oneline "$BASE"..HEAD    > "$OUT/commits.txt"
else
  git diff HEAD       > "$OUT/diff.patch"
  git diff --stat HEAD > "$OUT/diffstat.txt"
  echo "(base branch '$BASE' not found; diffed against HEAD)" > "$OUT/commits.txt"
fi
git diff HEAD > "$OUT/uncommitted.patch"   # anything not yet committed

# ---- summary ----------------------------------------------------------------
{
  echo "== $LABEL report $TS =="
  cat "$OUT/env.txt"; echo
  printf '%s\n' "${STEPS[@]}"; echo
  if [ -f "$OUT/jest.json" ] && command -v node >/dev/null 2>&1; then
    node -e '
      const r=require(process.argv[1]);
      console.log(`jest: ${r.numPassedTests}/${r.numTotalTests} tests passed, ${r.numFailedTests} failed, ${r.numTotalTestSuites} suites`);
    ' "$OUT/jest.json" 2>/dev/null
  fi
  [ -f "$OUT/coverage/coverage-summary.json" ] && node -e '
      const c=require(process.argv[1]).total;
      console.log(`coverage (all): lines ${c.lines.pct}%  branches ${c.branches.pct}%  functions ${c.functions.pct}%`);
    ' "$OUT/coverage/coverage-summary.json" 2>/dev/null
  echo; echo "diffstat:"; tail -n 1 "$OUT/diffstat.txt"
} > "$OUT/summary.txt"

# ---- compare with the previous run of this label ----------------------------
PREV="$(ls -1 "$REPORTS" 2>/dev/null | grep -E '^[0-9]{8}-[0-9]{6}$' | grep -v "^$TS$" | tail -n 1 || true)"
if [ -n "$PREV" ] && [ -f "$REPORTS/$PREV/summary.txt" ]; then
  diff -u "$REPORTS/$PREV/summary.txt" "$OUT/summary.txt" > "$OUT/vs-previous.txt" || true
fi

ln -sfn "$OUT" "$REPORTS/latest" 2>/dev/null || true
echo; cat "$OUT/summary.txt"
echo; echo "Report saved to: $OUT"
exit $FAIL
