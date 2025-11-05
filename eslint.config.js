import js from '@eslint/js';
import globals from 'globals';
import reactHooks from 'eslint-plugin-react-hooks';
import reactRefresh from 'eslint-plugin-react-refresh';
import tseslint from 'typescript-eslint';

export default tseslint.config(
  {
    // Broad ignores to avoid linting backend envs, vendor, and build outputs
    ignores: [
      'dist',
      'node_modules',
      '**/node_modules/**',
      'backend/**',
  '**/venv/**',
  '.venv/**',
      'coverage',
      '.vscode',
      'supabase/**',
    ],
  },
  {
    // TypeScript/React app sources
    extends: [js.configs.recommended, ...tseslint.configs.recommended],
  files: ['src/**/*.{ts,tsx}', 'vite.config.ts', 'vitest.config.ts', 'src/vite-env.d.ts'],
    languageOptions: {
      ecmaVersion: 2020,
      globals: globals.browser,
    },
    plugins: {
      'react-hooks': reactHooks,
      'react-refresh': reactRefresh,
    },
    rules: {
      ...reactHooks.configs.recommended.rules,
      'react-refresh/only-export-components': ['warn', { allowConstantExport: true }],
      // Relax overly strict rules that produced thousands of errors
      '@typescript-eslint/no-explicit-any': 'off',
      '@typescript-eslint/no-unused-vars': ['warn', { argsIgnorePattern: '^_' }],
      '@typescript-eslint/ban-ts-comment': 'off',
      '@typescript-eslint/no-empty-object-type': 'off',
      '@typescript-eslint/no-wrapper-object-types': 'off',
      '@typescript-eslint/no-unsafe-function-type': 'off',
      // Allow triple-slash references in env d.ts
      '@typescript-eslint/triple-slash-reference': 'off',
    },
  },
  {
    // Tests - even more relaxed to avoid noise
    files: ['src/tests/**/*.{ts,tsx}'],
    rules: {
      '@typescript-eslint/no-explicit-any': 'off',
      '@typescript-eslint/no-unused-vars': ['warn', { argsIgnorePattern: '^_' }],
    },
  }
);
