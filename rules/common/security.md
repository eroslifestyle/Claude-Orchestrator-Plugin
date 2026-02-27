# Security Rules

> Mandatory for ALL code. Violations are blocking - code MUST NOT ship with security issues.
> Inspired by OWASP Top 10, AgentShield, and real-world breach patterns.

---

## Secrets Management (Rules 1-8)

1. **NEVER hardcode** secrets, API keys, passwords, tokens, or connection strings
2. Use environment variables or a secrets manager (Vault, AWS SSM, Doppler)
3. `.env` files MUST be in `.gitignore` - never committed
4. Rotate secrets on suspected exposure - assume breach, act fast
5. Use different secrets per environment (dev/staging/prod)
6. Service accounts: use short-lived tokens over long-lived API keys
7. Never log secrets - mask them in output (`sk-...xxxx`)
8. Audit secret access: who accessed what, when

## Input Validation (Rules 9-18)

9. **ALWAYS validate/sanitize user input** at every system boundary
10. Use allowlists over denylists (define what IS valid, not what isn't)
11. Validate type, length, range, and format for every input field
12. Reject unexpected fields (don't silently ignore extra properties)
13. Use parameterized queries - **NEVER** concatenate strings for SQL
14. Validate and sanitize file paths to prevent path traversal (`../../../etc/passwd`)
15. Normalize unicode before validation (prevent homograph attacks)
16. Validate content-type matches actual content (don't trust headers alone)
17. Reject null bytes in string inputs
18. Set max request body size at the server/framework level

## Output Encoding (Rules 19-24)

19. **Escape all output** to prevent XSS (HTML-encode, JS-encode, URL-encode as needed)
20. Use Content-Security-Policy headers (no inline scripts/styles in production)
21. Set `X-Content-Type-Options: nosniff`
22. Set `X-Frame-Options: DENY` or use frame-ancestors CSP directive
23. Never reflect user input directly in error messages shown to other users
24. Sanitize HTML if rich text is required (use DOMPurify or equivalent)

## Authentication (Rules 25-34)

25. Hash passwords with **bcrypt** (cost 12+) or **argon2id** - NEVER MD5/SHA1/SHA256 for passwords
26. Enforce minimum password length (12+ chars) - don't cap max length below 128
27. Implement account lockout after 5 failed attempts (with progressive delay)
28. Use multi-factor authentication for admin/sensitive operations
29. Session tokens: cryptographically random, min 128 bits entropy
30. Invalidate sessions on password change and logout (server-side)
31. JWT: validate signature, check `exp`, `iss`, `aud` claims - reject `alg: none`
32. Use `httpOnly`, `secure`, `sameSite=Lax` (or Strict) for session cookies
33. Implement proper password reset flow (time-limited, single-use tokens)
34. Never reveal whether a username exists (use generic "invalid credentials" message)

## Authorization (Rules 35-42)

35. **Least privilege**: grant minimum permissions needed for each operation
36. Check permissions server-side on every request (not just UI hiding)
37. Use role-based (RBAC) or attribute-based (ABAC) access control
38. Validate object-level authorization (user can only access their own data - IDOR prevention)
39. Admin endpoints: separate authentication, IP restrictions, audit logging
40. API keys: scope to specific operations, not full access
41. File uploads: validate type, size, scan for malware, store outside webroot
42. Never trust client-side authorization checks

## Transport Security (Rules 43-48)

43. **HTTPS only** - redirect HTTP to HTTPS, use HSTS header
44. Validate SSL/TLS certificates - never disable verification
45. Use TLS 1.2+ only (disable SSLv3, TLS 1.0, TLS 1.1)
46. Pin certificates for mobile apps and critical internal services
47. Use strong cipher suites (AES-256-GCM, ChaCha20-Poly1305)
48. Encrypt sensitive data at rest (database, backups, logs)

## API Security (Rules 49-58)

49. **Rate limiting** on all public endpoints (auth: strict, others: reasonable)
50. Use CSRF tokens for all state-changing requests (or use SameSite cookies)
51. Implement proper CORS: restrict origins, methods, headers (never `*` in production)
52. API versioning: don't break clients, deprecate gracefully
53. Return consistent error format - never expose stack traces to end users
54. Validate request Content-Type header
55. Pagination: enforce max page size to prevent data dumping
56. Use API keys + OAuth2 for service-to-service communication
57. Implement request signing for webhook endpoints (HMAC-SHA256)
58. GraphQL: limit query depth and complexity to prevent DoS

## Data Protection (Rules 59-66)

59. **No sensitive data in URL params** (they appear in logs, referrer headers, browser history)
60. No sensitive data in application logs (PII, credentials, tokens)
61. Use constant-time comparison for secrets/tokens (prevent timing attacks)
62. Implement data retention policies - delete what you don't need
63. Anonymize/pseudonymize PII where full data isn't required
64. Encrypt sensitive fields in the database (not just the disk)
65. Secure backup storage with same controls as production data
66. Right to deletion: design for data erasure from the start

## Error Handling and Logging (Rules 67-74)

67. **Log security events**: authentication failures, authorization denied, input validation failures
68. Include context in security logs: timestamp, user ID, IP, action, resource
69. Never log passwords, tokens, or full credit card numbers
70. Use structured logging (JSON) for security events - easier to parse and alert
71. Send security logs to a centralized, tamper-evident system (SIEM)
72. Alert on anomalies: spike in auth failures, new IP for admin, unusual data access patterns
73. Return generic errors to users, detailed errors to logs
74. Don't catch and swallow security exceptions

## Dependency Security (Rules 75-80)

75. **Audit dependencies** regularly (`npm audit`, `pip-audit`, `govulncheck`)
76. Pin dependency versions in production (lockfiles committed)
77. No wildcard version ranges in production (`^` and `~` are OK, `*` is not)
78. Review new dependencies before adding: maintenance, security track record, license
79. Remove unused dependencies (reduce attack surface)
80. Use Dependabot/Renovate for automated security updates

## Code Execution Safety (Rules 81-86)

81. **No `eval()`, `exec()`, or `Function()` with user input** - ever
82. No dynamic `import()` with user-controlled paths
83. Subprocess calls: use arrays, not shell strings (`subprocess.run(["cmd", arg])` not `os.system(f"cmd {arg}")`)
84. Deserialize untrusted data safely (no pickle, no Java serialization - use JSON)
85. Sandbox untrusted code execution (containers, WASM, V8 isolates)
86. Template engines: use auto-escaping, disable unsafe features

## Infrastructure (Rules 87-92)

87. **Principle of least privilege** for service accounts, IAM roles, DB users
88. Network segmentation: DB not accessible from the internet
89. Enable audit logging on cloud resources (CloudTrail, etc.)
90. Use infrastructure as code (Terraform, Pulumi) - review changes like code
91. Container images: minimal base (Alpine/distroless), non-root user, no secrets baked in
92. Keep runtime/framework versions updated (patch vulnerabilities promptly)

## Agent/AI-Specific Security (Rules 93-100)

93. **Validate AI-generated code** before execution - never auto-execute blindly
94. Sanitize AI model outputs before displaying to users (LLM can generate XSS payloads)
95. Rate limit AI API calls and set spending caps
96. Don't pass raw user input to system prompts (prompt injection prevention)
97. Log all AI agent actions for auditability
98. Implement human-in-the-loop for destructive operations (delete, deploy, payment)
99. Restrict AI agent filesystem access to project directory only
100. Monitor AI agent resource usage (CPU, memory, API calls) - kill runaway processes
