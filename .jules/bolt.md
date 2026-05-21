## 2024-05-21 - Optimize Supabase Count Queries
**Learning:** In Supabase, fetching all records via `.select()` and then getting the list length causes excessive network payload, parsing overhead, and memory usage just to count matching records. This becomes an O(N) operation instead of O(1).
**Action:** Always use `.count(CountOption.exact)` for count queries when the actual row data is not needed. This returns an integer representing the count, saving bandwidth and processing time.
