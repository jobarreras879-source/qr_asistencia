## 2024-05-24 - Supabase Count Query Dart Return Type
**Learning:** In `supabase_flutter` v2+, chaining `.count(CountOption.exact)` followed by filter methods like `.gte()` returns a `PostgrestFilterBuilder<int>`. You can directly `await` this builder to get the integer count, rather than fetching a list of records or explicitly unpacking a `PostgrestResponse`.
**Action:** When querying Supabase just to get the number of matching rows, use `.count(CountOption.exact)` and directly `await` it as an integer to avoid unnecessary network payload and object parsing overhead.
