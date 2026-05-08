## 2024-05-08 - Supabase Row Counting
**Learning:** When querying Supabase just to get the number of matching rows, `.count(CountOption.exact)` is significantly more efficient than `.select()` because it avoids downloading all matching records to the client and parsing them into Dart structures. In `supabase_flutter` v2+, it returns a `PostgrestFilterBuilder<int>` which can be awaited directly as `Future<int>`.
**Action:** Always use `.count(CountOption.exact)` instead of `.select().then((data) => data.length)` when only the count of rows is needed.
