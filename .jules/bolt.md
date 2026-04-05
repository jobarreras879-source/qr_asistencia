## 2024-05-18 - [Supabase Query Optimization]
**Learning:** Using `.select().length` or downloading a payload to get the list size is an anti-pattern when using the Supabase client in Dart. In `supabase_flutter` v2+, using `.count(CountOption.exact)` directly returns the integer count without downloading the matching rows' payload to the client, preventing memory bloat and reducing network overhead for aggregate queries.
**Action:** When querying Supabase just to count matching rows, always use `.count(CountOption.exact)` instead of returning a `.select()` array length.
