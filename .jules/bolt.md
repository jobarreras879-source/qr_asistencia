## 2024-05-24 - Supabase Count Query Performance
**Learning:** Using `.select()` just to find the length of a result set causes significant memory and network overhead by fetching all matching rows into memory.
**Action:** When only the count of records is needed, always use `.count(CountOption.exact)` which offloads the calculation to the database and only returns an integer, avoiding large payload transfers and parsing.
