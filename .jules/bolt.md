## 2024-05-17 - Optimize count queries in Supabase
**Learning:** Using `.select()` and counting rows in Dart for Supabase queries causes unnecessary network payload and memory overhead compared to database-level counting.
**Action:** Always use `.count(CountOption.exact)` when only the number of matching rows is needed.