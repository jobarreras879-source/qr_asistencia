## 2025-02-14 - Optimize Supabase Count Queries
**Learning:** Using `.select()` just to get a row count downloads all matching records and parses them into Dart Maps, causing unnecessary memory allocation and network overhead.
**Action:** When querying Supabase just to get the number of matching rows, use `.count(CountOption.exact)` instead of `.select()` to return an integer directly from the database.
