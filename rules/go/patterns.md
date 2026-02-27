# Go Patterns and Rules

> Go-specific standards. Supplements `rules/common/` rules.

---

## Philosophy

- Follow **Effective Go** and the **Go Proverbs**
- "Clear is better than clever"
- "A little copying is better than a little dependency"
- "Don't communicate by sharing memory; share memory by communicating"
- Accept the Go way - don't force patterns from other languages

## Error Handling

- **Always check returned errors** - never use `_` to discard errors
- Wrap errors with context: `fmt.Errorf("doing something: %w", err)`
- Use `errors.Is()` and `errors.As()` for error comparison - **never string matching**
- Define sentinel errors for expected conditions: `var ErrNotFound = errors.New("not found")`
- Custom error types for errors that carry data (implement `Error() string` on a struct with relevant fields)
- Don't panic in library code - return errors. Panic is for truly unrecoverable bugs

## Interfaces

- Define interfaces **at the consumption site**, not the definition site
- Keep interfaces **small**: 1-3 methods (the bigger the interface, the weaker the abstraction)
- Accept interfaces, return structs
- Standard library examples: `io.Reader`, `io.Writer`, `fmt.Stringer`
  ```go
  type UserStore interface { GetByID(ctx context.Context, id string) (*User, error) }  // consumer defines
  type PostgresUserStore struct { db *sql.DB }  // implementation satisfies implicitly
  ```

## Context

- **First parameter** of functions that do I/O or may be cancelled: `ctx context.Context`
- Never store context in structs - pass it through function calls
- Use `context.WithTimeout()` / `context.WithCancel()` for cancellation
- Check `ctx.Err()` in long-running loops
- Use `context.WithValue()` sparingly - only for request-scoped data (trace ID, auth)

## Concurrency

- Channel direction in function signatures:
  ```go
  func producer(out chan<- int) { ... }   // send-only
  func consumer(in <-chan int) { ... }     // receive-only
  ```
- Use `sync.WaitGroup` for waiting on multiple goroutines
- Use `sync.Once` for one-time initialization
- Use `sync.Mutex` for shared state - keep critical sections small
- Prefer channels for communication, mutexes for state protection
- Always handle goroutine lifecycle: ensure they can be stopped (context, done channel)
- Use `errgroup.Group` for goroutines that return errors

## Structs and Composition

- **Prefer composition over inheritance** (Go has no inheritance)
- Embed structs for shared behavior:
  ```go
  type BaseModel struct {
      ID        string
      CreatedAt time.Time
      UpdatedAt time.Time
  }
  type User struct {
      BaseModel
      Name  string
      Email string
  }
  ```
- Use functional options for complex constructors:
  ```go
  type Option func(*Server)
  func WithPort(p int) Option { return func(s *Server) { s.port = p } }
  func NewServer(opts ...Option) *Server { ... }
  ```

## Testing

- **Table-driven tests** as the default pattern:
  ```go
  tests := []struct { name string; input string; expected int; wantErr bool }{
      {"empty input", "", 0, true},
      {"valid input", "42", 42, false},
  }
  for _, tt := range tests {
      t.Run(tt.name, func(t *testing.T) { /* assert got vs tt.expected, err vs tt.wantErr */ })
  }
  ```
- Use `testify` for assertions if table-driven gets verbose
- Use `httptest` for HTTP handler tests
- Use `t.Parallel()` for independent tests
- Test helpers: use `t.Helper()` so failures report the caller's line

## Naming

- Short variable names for small scopes: `r` for reader, `w` for writer, `ctx` for context
- Longer names for larger scopes and exported identifiers
- Acronyms: all caps (`HTTP`, `URL`, `ID`) not `Http`, `Url`, `Id`
- Package names: short, lowercase, no underscores (`httputil` not `http_util`)
- Getters: `Name()` not `GetName()` (Go convention)

## Project Structure

- Follow standard Go layout: `cmd/myapp/main.go`, `internal/` (domain, handler, service, repository), `pkg/`, `go.mod`, `Makefile`

## Tooling

- **`go vet`** + **`staticcheck`** in CI (mandatory)
- **`golangci-lint`** for comprehensive linting
- **`go fmt`** / **`goimports`** for formatting (enforced by CI)
- **`go mod tidy`** before committing
- Use build tags for platform-specific or integration test code

## Performance

- Use `strings.Builder` for string concatenation in loops
- Preallocate slices when size is known: `make([]T, 0, expectedSize)`
- Use `sync.Pool` for frequently allocated/deallocated objects
- Profile before optimizing: `pprof`, `trace`, benchmarks
- Write benchmarks for performance-critical code
