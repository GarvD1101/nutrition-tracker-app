#!/usr/bin/env bash
# check-structure.sh : enforce STRUCTURE.md rules. Exit 1 on any violation.
# Checks: (1) repo-root allow-list, (2) allowed src/ top-level folders,
#         (3) file-length limits, (4) domain purity (no react/react-native/navigation/native/data imports),
#         (5) no Expo (R13).
set -uo pipefail
ROOT="$(git rev-parse --show-toplevel)"
cd "$ROOT"
FAIL=0
err() { echo "STRUCTURE VIOLATION: $*" >&2; FAIL=1; }

# Tracked + untracked-but-not-ignored files (so stray new files are caught too)
mapfile -t FILES < <(git ls-files --cached --others --exclude-standard)

ROOT_FILES=" README.md LICENSE .gitignore .gitattributes .editorconfig .gitleaks.toml "
ROOT_DIRS=" app data shared eval scripts docs .github "

# (1) root allow-list
for f in "${FILES[@]}"; do
  top="${f%%/*}"
  if [[ "$f" == */* ]]; then
    [[ "$ROOT_DIRS" == *" $top "* ]] || err "directory not allowed at repo root: $top/ (file: $f)"
  else
    [[ "$ROOT_FILES" == *" $f "* ]] || err "file not allowed at repo root: $f"
  fi
done

# (2) allowed folders directly under app/src
SRC_OK=" navigation screens features domain data native services ui config types "
for f in "${FILES[@]}"; do
  if [[ "$f" == app/src/*/* ]]; then
    d="${f#app/src/}"; d="${d%%/*}"
    [[ "$SRC_OK" == *" $d "* ]] || err "unknown folder under app/src: $d/ (file: $f)"
  elif [[ "$f" == app/src/* ]]; then
    err "file directly under app/src (must be inside a layer folder): $f"
  fi
done

# (3) length limits (tests, generated and SQL migrations exempt)
for f in "${FILES[@]}"; do
  [[ -f "$f" ]] || continue
  case "$f" in
    *__tests__/*|*.test.ts|*.test.tsx|app/test/*|*/src/test/*) continue ;;
  esac
  case "$f" in
    app/src/*.ts|app/src/*.tsx|app/src/*/*.ts|app/src/*/*.tsx|app/src/*/*/*.ts|app/src/*/*/*.tsx) max=250 ;;
    *.kt) max=300 ;;
    *) continue ;;
  esac
  n=$(wc -l < "$f")
  (( n > max )) && err "$f has $n lines (limit $max)"
done

# (4) domain purity
if [[ -d app/src/domain ]]; then
  hits=$(grep -rnE "from ['\"](react|react-native|@react-navigation[^'\"]*|expo[^'\"]*|@/(data|native|features|ui|services))|require\(['\"](react|react-native|expo)" \
         app/src/domain --include='*.ts' --include='*.tsx' 2>/dev/null | grep -vE "__tests__|\.test\." || true)
  [[ -n "$hits" ]] && err "domain/ must stay pure. Offending imports:"$'\n'"$hits"
fi

# (5) R13: no Expo
if [[ -f app/package.json ]] && grep -qE '"(expo|expo-[a-z0-9-]+|eas-cli)"' app/package.json; then
  err "Expo packages found in app/package.json (R13: bare React Native only)"
fi
for f in "${FILES[@]}"; do
  case "$f" in app/eas.json|app/app.config.*) err "Expo file not allowed (R13): $f" ;; esac
done

if (( FAIL == 0 )); then echo "check-structure: OK"; fi
exit $FAIL
