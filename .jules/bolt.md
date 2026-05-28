## 2025-02-12 - Supabase .count() Performance Pattern
**Learning:** In `supabase_flutter` v2+, the `.count(CountOption.exact)` query builder returns a `PostgrestFilterBuilder<int>` which can be chained and directly awaited to return an integer. Previously, queries downloading the entire dataset and measuring list length caused significant network and memory overhead.
**Action:** When querying Supabase just to get the number of matching rows, always use `.count(CountOption.exact)` instead of `.select()` to push the computation to the database level.
