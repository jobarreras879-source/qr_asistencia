## 2024-06-25 - Supabase count queries
**Learning:** When needing only the count of rows matching a query in Supabase, using `.select()` downloads all matching records to the client and parses them into Dart structures.
**Action:** Always use `.count(CountOption.exact)` instead of `.select()` when only the row count is required, to minimize network transfer and client-side memory usage, especially for large datasets. Wait for the query directly as it resolves to a Future<int>.
