## 2025-05-19 - Use .count(CountOption.exact) for Faster Supabase Counts
**Learning:** In Supabase, if you only need the count of records matching certain conditions, calling `.select()` and then getting the length of the returned list requires downloading all matching records to the client and parsing them.
**Action:** Use `.count(CountOption.exact)` (chained with filters like `.eq`, `.gte`) and await the `PostgrestFilterBuilder<int>` directly. This is much faster and more memory-efficient as the counting is done on the database side.
