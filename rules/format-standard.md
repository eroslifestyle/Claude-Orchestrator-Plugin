# Rules Format Standard

> This document defines the standard format for all rules files in the `rules/` directory.
> All rules files MUST follow this format for consistency.

---

## Format Specification

All rules files MUST use this format:
1. **Numbered list format** (preferred for common rules):
   ```markdown
   ## Category Name (Rules X-y)

   1. **Rule title** - description
   2. **Rule title** - description
   ```

2. **Heading format** (acceptable but discouraged for new rules):
   ```markdown
   ## Category Name (Rules x-y)

   ### Rule N
   **Rule title**
   Description text here
   ```

---

## Migration Guide
Existing files using the heading format (coding-style.md, testing.md, git-workflow.md) should be migrated to the numbered list format for consistency.

---

## Examples
See `security.md`, `database.md`, `api-design.md` for the correct format.
