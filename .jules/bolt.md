## 2024-05-12 - Supabase Count Query Optimization
**Learning:** Using `.select()` and then `.length` to count rows downloads all matching rows to the client, which is inefficient.
**Action:** Use `.count(CountOption.exact)` which returns an `int` directly and avoids downloading rows.
