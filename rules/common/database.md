# Database Rules

> Mandatory for ALL database code. Supplements `rules/common/security.md` for data layer.

---

## Query Safety (Rules 1-8)

1. **ALWAYS use parameterized queries** - never concatenate user input into SQL
2. Use ORM query builders when available (SQLAlchemy, Prisma, GORM)
3. Validate and sanitize all input before it reaches the query layer
4. Limit result sets with pagination (LIMIT/OFFSET or cursor-based)
5. Set query timeouts to prevent long-running queries from blocking
6. Use read replicas for read-heavy queries when available
7. Never expose raw database errors to end users
8. Log slow queries (>100ms) with query plan for investigation

## Schema Design (Rules 9-16)

9. **Every table must have a primary key** - prefer UUID or ULID over auto-increment for distributed systems
10. Add created_at and updated_at timestamps to every table
11. Use foreign keys to enforce referential integrity
12. Normalize to 3NF by default, denormalize only with measured performance justification
13. Use appropriate column types (don't store dates as strings, money as float)
14. Add NOT NULL constraints wherever the business logic requires a value
15. Use CHECK constraints for value range validation at DB level
16. Document schema changes in migration files (never modify DB manually)

## Indexing (Rules 17-24)

17. **Index foreign keys** - always, no exceptions
18. Index columns used in WHERE, JOIN, and ORDER BY clauses
19. Use composite indexes for multi-column queries (leftmost prefix rule)
20. Avoid over-indexing: each index slows writes, audit unused indexes quarterly
21. Use partial indexes for queries on subsets of data (WHERE active = true)
22. Use EXPLAIN/EXPLAIN ANALYZE before and after adding indexes
23. Monitor index usage and drop unused indexes
24. Covering indexes for frequently-read columns to avoid table lookups

## Connection Management (Rules 25-30)

25. **Always use connection pooling** - never open/close per request
26. Set pool size based on load (start: 10-20 connections, tune with monitoring)
27. Set connection timeout (5s default) and idle timeout (300s default)
28. Handle connection failures gracefully with retry logic
29. Close connections properly (use context managers / try-finally)
30. Monitor pool metrics: active, idle, waiting, timeouts

## Performance (Rules 31-38)

31. **Avoid N+1 queries** - use JOINs or batch loading (dataloader pattern)
32. Use database-level pagination, never fetch all rows and paginate in code
33. Cache frequently-read, rarely-changed data (with invalidation strategy)
34. Use bulk inserts for batch operations (not individual INSERT in a loop)
35. Minimize round trips: batch related queries when possible
36. Use appropriate transaction isolation levels (READ COMMITTED default)
37. Keep transactions short - no external API calls inside transactions
38. Profile and optimize queries exceeding 100ms

## Migrations (Rules 39-44)

39. **Every schema change goes through a migration file** - version controlled
40. Migrations must be reversible (UP and DOWN)
41. Test migrations on a copy of production data before deploying
42. Never drop columns/tables in the same deploy as code changes (two-phase)
43. Add new columns as nullable first, backfill, then add NOT NULL
44. Lock-free migrations for large tables (pt-online-schema-change or equivalent)

## Data Protection (Rules 45-50)

45. **Encrypt sensitive columns** (PII, financial data) at application level
46. Implement soft deletes for audit-critical data (deleted_at timestamp)
47. Backup daily, test restore monthly - untested backups don't exist
48. Use row-level security (RLS) where supported for multi-tenant data
49. Audit trail: log who changed what and when for sensitive tables
50. Data retention: define and enforce deletion policies per data type
