// eslint.config.js
export default [
  {
    files: ["**/*.js"],
    languageOptions: {
      globals: {
        // Add global variables if necessary
        process: "readonly",
        __dirname: "readonly",
      },
    },
    rules: {
      quotes: ["error", "double"],
      indent: ["error", 2],
    },
  },
];
