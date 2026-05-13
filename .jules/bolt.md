## 2024-05-13 - [Supabase Count Optimization]
**Learning:** In Supabase Flutter v2+, querying the number of matching rows using `.select()` is extremely inefficient as it downloads all rows to the client only to get their length.
**Action:** Use `.count(CountOption.exact)` instead, which returns a `PostgrestFilterBuilder<int>` allowing direct async evaluation of the count without fetching data.
