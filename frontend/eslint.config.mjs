import { dirname } from "path";
import { fileURLToPath } from "url";
import { FlatCompat } from "@eslint/eslintrc";

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

const compat = new FlatCompat({
  baseDirectory: __dirname,
});

const eslintConfig = [
  ...compat.extends(
    "next/core-web-vitals", 
    "next/typescript",
    "@typescript-eslint/recommended",
    "prettier"
  ),
  {
    rules: {
      // Enforce consistent code style
      "@typescript-eslint/no-unused-vars": "error",
      "@typescript-eslint/prefer-const": "error",
      "prefer-template": "error",
      "no-console": "warn",
      
      // React-specific rules
      "react/jsx-boolean-value": ["error", "never"],
      "react/self-closing-comp": "error",
    },
  },
];

export default eslintConfig;
