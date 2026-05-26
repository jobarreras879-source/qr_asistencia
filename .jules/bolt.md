## 2024-05-24 - Supabase `.count()` vs `.select()`
**Learning:** Using `.select()` and counting locally downloads all rows, wasting bandwidth/memory, especially when only the row count is needed.
**Action:** Use `.count(CountOption.exact)` for count queries in Supabase so that only the integer count is downloaded and returned over the network, drastically reducing overhead.
