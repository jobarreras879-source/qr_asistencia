## 2024-05-24 - Supabase Record Count Optimization
**Learning:** Using `.select()` just to get the length of matching records downloads all rows to the client and parses them into memory, which is a major bottleneck for large datasets in Supabase.
**Action:** Always use `.count(CountOption.exact)` when only the number of matching rows is needed. In supabase_flutter v2+, this directly returns a `Future<int>` avoiding `PostgrestResponse` parsing entirely.
