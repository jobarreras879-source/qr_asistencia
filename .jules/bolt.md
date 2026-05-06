
## 2024-05-18 - Supabase Row Counting Optimization
**Learning:** Using `.select()` in Supabase to fetch rows just to count them in Dart (`List.length`) pulls unnecessary data over the network, causing a bottleneck.
**Action:** Always use `.count(CountOption.exact)` for counting rows to push the aggregation to the database layer, returning only an integer (`O(1)` memory) instead of `O(N)` objects.
