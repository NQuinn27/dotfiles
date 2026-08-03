When modifying dependencies:

- Add or remove packages with the project's package manager instead of manually editing package manifests, unless no package-manager command is available.

After making code changes:

- Run the project's existing check, format, lint, and relevant test commands.
- If useful validation commands are missing, suggest adding them.

When working in TypeScript:

- Prefer type inference over unnecessary explicit return types.
- Treat `as any` as a last resort; prefer real type-safe solutions.

When clarification is needed, ask questions one at a time.

When modifying global Pi configuration or extensions:

- Prefer a standalone extension file for small features without extra dependencies; use a directory package for multi-file extensions or extension-specific dependencies.
- Keep TypeScript extensions ESM-only and under strict type checking.
- Put dependencies in the nearest appropriate package, and never commit `node_modules`.
- Treat authentication, sessions, model stores, and other runtime state as sensitive data that should not be copied into tracked configuration or logs.
- After extension changes, run the available type checks and tests, then reload Pi with `/reload`.
