## 2024-05-19 - [Supabase Count Query Optimization]
**Learning:** Using `.select()` to count rows in Supabase forces the server to return all matched rows, increasing network bandwidth and memory overhead, especially for large datasets.
**Action:** Always use `.count(CountOption.exact)` when only the number of rows is needed, which performs a fast `COUNT(*)` on the database and returns only an integer.
