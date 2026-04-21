## 2024-04-21 - Supabase Record Counting
**Learning:** Using `.select().length` downloads all matching rows to the client, consuming memory and bandwidth unnecessarily. In `supabase_flutter` v2+, `.count(CountOption.exact)` directly returns a `Future<int>` for the row count.
**Action:** Always use `.count(CountOption.exact)` when querying Supabase solely to obtain the number of matching rows.
