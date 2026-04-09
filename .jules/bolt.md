## 2024-04-09 - Use .count() instead of .select() in Supabase queries
**Learning:** Fetching all rows via .select() just to get the length is an O(N) memory anti-pattern. Using .count(CountOption.exact) is O(1) memory client-side and significantly faster.
**Action:** Always prefer .count() when only needing the number of matching records to avoid unnecessarily large payload downloads.
