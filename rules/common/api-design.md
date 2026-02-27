# API Design Rules

> Standards for REST APIs, GraphQL, and service-to-service communication.

---

## Resource Naming (Rules 1-8)

1. **Use plural nouns for resources** - `/users`, `/orders`, not `/user`, `/order`
2. Use kebab-case for multi-word resources: `/order-items`, not `/orderItems`
3. Nest resources max 2 levels deep: `/users/{id}/orders` (not `/users/{id}/orders/{id}/items/{id}`)
4. Use query parameters for filtering, sorting, pagination: `/users?status=active&sort=name`
5. Actions that don't map to CRUD: use verbs as sub-resources `/orders/{id}/cancel`
6. Version in URL path: `/api/v1/users` (not headers, not query params)
7. Consistent naming across the entire API - audit for inconsistencies
8. No file extensions in URLs: `/users/123`, not `/users/123.json`

## HTTP Methods (Rules 9-16)

9. **GET**: read-only, idempotent, cacheable - never modify state
10. **POST**: create new resources, return 201 + Location header
11. **PUT**: full resource replacement, idempotent - client sends complete object
12. **PATCH**: partial update, send only changed fields (JSON Merge Patch or JSON Patch)
13. **DELETE**: remove resource, return 204 (no content) - idempotent
14. Return 405 Method Not Allowed for unsupported methods on a resource
15. HEAD and OPTIONS should work on all endpoints (CORS preflight needs OPTIONS)
16. Never use GET for state-changing operations (side-effect free)

## Status Codes (Rules 17-26)

17. **200**: Success (GET, PUT, PATCH with body)
18. **201**: Created (POST) - include Location header
19. **204**: No Content (DELETE, PUT/PATCH without body)
20. **400**: Bad Request - invalid input (include field-level errors)
21. **401**: Unauthorized - missing or invalid authentication
22. **403**: Forbidden - authenticated but insufficient permissions
23. **404**: Not Found - resource doesn't exist
24. **409**: Conflict - duplicate key, version conflict
25. **422**: Unprocessable Entity - valid syntax but semantic errors
26. **429**: Too Many Requests - rate limited (include Retry-After header)

## Request/Response Format (Rules 27-34)

27. **JSON by default** - use Content-Type: application/json
28. Consistent envelope: `{ "data": {...}, "meta": {...} }` or flat (pick one)
29. Error format: `{ "error": { "code": "VALIDATION_ERROR", "message": "...", "details": [...] } }`
30. Dates in ISO 8601 format: `2026-02-26T14:30:00Z` (always UTC)
31. Use camelCase for JSON field names (matches JavaScript convention)
32. Null fields: include with `null` value, don't omit (explicit > implicit)
33. Large collections: always paginate with `limit`, `offset` or `cursor`, `next`
34. Include `total_count` in paginated responses (or `has_more` boolean)

## Authentication and Security (Rules 35-40)

35. **Use Bearer tokens** in Authorization header (not query params, not cookies for APIs)
36. Validate tokens on every request - never trust client-side claims
37. Rate limit by API key + IP: strict for auth endpoints, reasonable for others
38. CORS: restrict origins, never use `*` in production
39. Require HTTPS - reject plain HTTP requests
40. Sensitive data never in URL params (tokens, passwords, PII)

## Versioning and Evolution (Rules 41-46)

41. **Never break existing clients** - additive changes only within a version
42. New optional fields are non-breaking; removing/renaming fields is breaking
43. Deprecate before removing: add Sunset header + docs notice, minimum 6 months
44. Major version bump (v1 -> v2) only for breaking changes
45. Support at least N-1 version (current + previous)
46. Document all changes in API changelog with migration guide

## Documentation (Rules 47-50)

47. **OpenAPI/Swagger spec** for every REST API - auto-generated from code when possible
48. Every endpoint: method, path, description, request body, response body, error codes
49. Include example requests and responses for every endpoint
50. Keep docs in sync with code - CI check for spec drift
