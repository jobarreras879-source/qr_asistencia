## 2024-04-27 - Supabase query optimization
**Learning:** Using `.select()` to retrieve data just to get the count of matching rows downloads all matching rows to the client and parses them, which introduces significant overhead.
**Action:** Replace `.select()` with `.count(CountOption.exact)` for count queries to offload the counting directly to the Supabase database. Since the SDK provides `CountOption.exact`, it reduces network and memory overhead.
