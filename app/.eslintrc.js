module.exports = {
  root: true,
  extends: ['@react-native'],
  plugins: ['boundaries'],
  ignorePatterns: ['coverage/**', 'node_modules/**', 'android/**', '.husky/**'],
  settings: {
    'boundaries/root-path': __dirname.replace(/\\/g, '/'),
    'import/resolver': {
      node: {
        extensions: ['.js', '.jsx', '.ts', '.tsx'],
      },
    },
    'boundaries/elements': [
      { type: 'navigation', pattern: ['src/navigation', 'src/navigation/*'] },
      { type: 'screens', pattern: ['src/screens', 'src/screens/*'] },
      { type: 'features', pattern: 'src/features/*', capture: ['feature'] },
      { type: 'domain', pattern: ['src/domain', 'src/domain/*'] },
      { type: 'data', pattern: ['src/data', 'src/data/*'] },
      { type: 'native', pattern: ['src/native', 'src/native/*'] },
      { type: 'services', pattern: ['src/services', 'src/services/*'] },
      { type: 'ui', pattern: ['src/ui', 'src/ui/*'] },
      { type: 'config', pattern: ['src/config', 'src/config/*'] },
      { type: 'types', pattern: ['src/types', 'src/types/*'] },
    ],
    'boundaries/ignore': ['**/*.test.*', '**/__tests__/**', 'test/**'],
  },
  rules: {
    complexity: ['error', 10],
    'max-lines': ['error', { max: 250, skipBlankLines: true, skipComments: true }],
    'boundaries/dependencies': [
      'error',
      {
        default: 'disallow',
        policies: [
          {
            from: { element: { type: ['navigation', 'screens'] } },
            allow: [{ to: { element: { type: ['navigation', 'screens', 'features', 'ui', 'config', 'types'] } } }],
          },
          {
            from: { element: { type: 'features' } },
            allow: [
              {
                to: {
                  element: {
                    type: ['domain', 'data', 'native', 'services', 'ui', 'config', 'types'],
                  },
                },
              },
              {
                to: {
                  element: {
                    type: 'features',
                    captured: { feature: '{{from.captured.feature}}' },
                  },
                },
              },
            ],
          },
          {
            from: { element: { type: 'domain' } },
            allow: [{ to: { element: { type: ['domain', 'config', 'types'] } } }],
          },
          {
            from: { element: { type: 'data' } },
            allow: [{ to: { element: { type: ['data', 'domain', 'config', 'types'] } } }],
          },
          {
            from: { element: { type: 'native' } },
            allow: [{ to: { element: { type: ['native', 'domain', 'config', 'types'] } } }],
          },
          {
            from: { element: { type: 'services' } },
            allow: [{ to: { element: { type: ['services', 'domain', 'config', 'types'] } } }],
          },
          {
            from: { element: { type: 'ui' } },
            allow: [{ to: { element: { type: ['ui', 'domain', 'config', 'types'] } } }],
          },
          {
            from: { element: { type: 'config' } },
            allow: [{ to: { element: { type: ['config', 'types'] } } }],
          },
          {
            from: { element: { type: 'types' } },
            allow: [{ to: { element: { type: 'types' } } }],
          },
        ],
      },
    ],
  },
  overrides: [
    {
      files: ['test/**/*', '**/*.test.*', '**/__tests__/**'],
      rules: {
        'max-lines': 'off',
        complexity: 'off',
      },
    },
  ],
};
