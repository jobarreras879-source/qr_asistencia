
## 2024-05-18 - Optimize record count query
**Learning:** In Supabase, using `.select()` just to count matching records downloads all matching records to the client and parses them into Dart structures. For simple count aggregations, using `.count(CountOption.exact)` avoids unnecessary payload downloading and returns an integer count directly.
**Action:** When querying Supabase just to get the number of matching rows, use `.count(CountOption.exact)` instead of `.select()` to avoid downloading all matching records to the client.
