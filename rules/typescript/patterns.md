# TypeScript Patterns and Rules

> TypeScript-specific standards. Supplements `rules/common/` rules.

---

## Compiler Configuration

- **`strict: true`** in tsconfig.json - always, no exceptions
- Enable additional strict checks:
  ```json
  {
    "noUncheckedIndexedAccess": true,
    "noPropertyAccessFromIndexSignature": true,
    "exactOptionalPropertyTypes": true
  }
  ```
- Target: ES2022+ for modern environments, ES2020 for broader compat
- Use `"moduleResolution": "bundler"` or `"node16"` (not `"node"`)

## Type Safety

- **Avoid `any`** - use `unknown` with type guards, or define the actual type
- If `any` is truly needed, add `// eslint-disable-next-line @typescript-eslint/no-explicit-any` with a comment explaining why
- Use `unknown` for external data (API responses, user input) + validate at boundary
- Prefer type narrowing (type guards, discriminated unions) over type assertions (`as`)
- Type assertions (`as X`) are code smells - use them only after exhausting alternatives
- Never use `!` (non-null assertion) except in test code

## Types vs Interfaces

- **Interfaces** for object shapes (extensible, better error messages):
  ```typescript
  interface User {
    readonly id: string;
    name: string;
    email: string;
  }
  ```
- **Type aliases** for unions, intersections, mapped types, primitives:
  ```typescript
  type Status = "active" | "inactive" | "suspended";
  type Result<T> = { ok: true; data: T } | { ok: false; error: Error };
  ```
- Use `const` assertions for literal types:
  ```typescript
  const ROLES = ["admin", "user", "guest"] as const;
  type Role = (typeof ROLES)[number]; // "admin" | "user" | "guest"
  ```

## Discriminated Unions

- Use discriminated unions for state machines and variant types:
  ```typescript
  interface Loading { status: "loading" }
  interface Success { status: "success"; data: User[] }
  interface Failure { status: "error"; error: string }
  type State = Loading | Success | Failure;
  ```
- Exhaustive checking with `never`: `function assertNever(x: never): never { throw new Error(...) }`

## Immutability

- **`readonly`** for properties that shouldn't change after creation
- **`ReadonlyArray<T>`** or `readonly T[]` for arrays that shouldn't be mutated
- **`Readonly<T>`** for freezing entire objects
- **`as const`** for literal objects and arrays
- Prefer `map`/`filter`/`reduce` over mutating loops

## Runtime Validation

- Use **zod** or **valibot** for runtime validation of external data:
  ```typescript
  const UserSchema = z.object({
    id: z.string().uuid(),
    name: z.string().min(1).max(100),
    email: z.string().email(),
  });
  type User = z.infer<typeof UserSchema>;
  ```
- Validate at system boundaries: API handlers, env vars, config files, message queues
- Never trust `JSON.parse()` output without validation

## Error Handling

- Use Result types for expected failures:
  ```typescript
  type Result<T, E = Error> =
    | { ok: true; value: T }
    | { ok: false; error: E };
  ```
- Use `try/catch` for unexpected failures (I/O, network)
- Define domain-specific error classes extending `Error`
- Never catch and ignore errors (at minimum, log them)
- Use `cause` property for error chaining: `new Error("msg", { cause: originalError })`

## Exports and Modules

- **Named exports only** - no default exports (better refactoring, auto-imports)
- Barrel exports (`index.ts`) only at module boundaries, not inside modules
- One export per concept (don't export internal helpers)
- Re-export types explicitly: `export type { User } from "./user"`

## Async Patterns

- Always handle Promise rejections (`.catch()` or `try/catch` with `await`)
- Use `Promise.all()` for concurrent independent operations
- Use `Promise.allSettled()` when partial failure is acceptable
- Set timeouts on external calls: `AbortController` with `signal`
- Avoid `new Promise()` constructor when `async/await` works

## Null Handling

- Prefer `undefined` over `null` (TypeScript convention)
- Use optional chaining `?.` and nullish coalescing `??`
- Never use `== null` to check both null and undefined (use `=== undefined` or `=== null`)
- Use `NonNullable<T>` to strip null/undefined from types

## Testing (TypeScript-Specific)

- Use **vitest** or **jest** with `ts-jest` preset
- Type-test with `tsd` or `expect-type` for library types
- Use `satisfies` for compile-time type checking without widening
- Mock with `vi.mock()` (vitest) or `jest.mock()` - type-safe mocks

## Linting and Formatting

- **ESLint** with `@typescript-eslint/recommended-type-checked`
- **Prettier** for formatting (no style debates)
- Sort imports with `eslint-plugin-import` or `@trivago/prettier-plugin-sort-imports`
- Pre-commit hooks with `lint-staged` + `husky`

## Project Structure

```
src/
  modules/<feature>/          # controller, service, repository, types, schema, __tests__/
  shared/types|utils|middleware/
  index.ts
tsconfig.json
```
