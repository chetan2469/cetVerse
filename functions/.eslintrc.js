module.exports = {
  env: {
    es6: true,
    node: true,
  },
  parserOptions: {
    'ecmaVersion': 2018,
  },
  extends: [
    'eslint:recommended',
    'google',
  ],
  rules: {
    'object-curly-spacing': 'off',
    'comma-dangle': 'off',
    'max-len': 'off',
    'require-jsdoc': 'off',
    'prefer-arrow-callback': 'off'
  },
  overrides: [
    {
      files: ['**/*.spec.*'],
      env: {
        mocha: true,
      },
      rules: {},
    },
  ],
  globals: {},
};
