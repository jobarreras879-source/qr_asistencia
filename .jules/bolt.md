## 2024-05-24 - Performance Optimizations
**Learning:** Found an inefficient count operation in Supabase queries. Downloading all matched rows to memory and mapping them to a list just to count the number of elements is unnecessary and causes an unneeded memory overhead as the records grow.
**Action:** Replace .select() and getting the length of a List with .count(CountOption.exact) on Supabase builder, which fetches only the integer count.
