## 2024-05-24 - Optimize Supabase count queries
**Learning:** When querying Supabase just to get the number of matching rows, `.select()` downloads all matching records to the client and parses them into a Dart List, leading to high network usage and memory overhead. Supabase provides `.count(CountOption.exact)` which computes the count server-side and returns a simple integer.
**Action:** Always use `.count(CountOption.exact)` instead of downloading the whole dataset when only the length/number of rows is needed.
