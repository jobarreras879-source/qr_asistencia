## 2024-04-24 - Supabase count optimization
**Learning:** Using `.select()` and downloading all matching rows to calculate the length locally is inefficient. In supabase_flutter v2+, `count(CountOption.exact)` directly chains and returns an int without downloading data.
**Action:** Always use `.count(CountOption.exact)` for row counting when you only need the number of matching rows.
