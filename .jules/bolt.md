## 2024-05-18 - [Supabase Counting Optimization]
**Learning:** Supabase's `.count(CountOption.exact)` returns a `PostgrestFilterBuilder<int>` which can be chained and directly awaited as a future, avoiding downloading and parsing rows in Dart.
**Action:** Use `.count(CountOption.exact)` instead of `.select()` and local `List.length` when only row counts are needed.