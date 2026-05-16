## 2024-05-16 - Use server-side count in Supabase queries
**Learning:** When querying Supabase just to get the number of matching rows, using `.count(CountOption.exact)` instead of `.select()` avoids downloading all matching records to the client and parsing them into Dart structures. The `.count()` query builder method returns a `PostgrestFilterBuilder<int>` which can be awaited directly.
**Action:** Always prefer `.count(CountOption.exact)` over fetching data and checking `.length` when only the count is needed to save memory and bandwidth.
