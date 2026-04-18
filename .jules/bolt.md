## 2025-02-12 - Supabase Count Performance Pattern
**Learning:** When querying Supabase just to get the number of matching rows, `.count(CountOption.exact)` directly returns an integer and is significantly faster than `.select()` which downloads all matching records and parses them into Dart Maps before counting them locally.
**Action:** Always prefer `.count(CountOption.exact)` over `.select()` when only the total row count is needed to avoid unnecessary network data transfer and parsing overhead.
