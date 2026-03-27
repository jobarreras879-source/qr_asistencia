
## 2024-05-18 - Optimize getTodayCount to use count instead of select
**Learning:** In Supabase, if you only need the number of matching records, using `.count(CountOption.exact)` avoids downloading all rows to the client and parsing them, which is a significant performance bottleneck and memory overhead when data grows.
**Action:** Replace `.select()` with `.count(CountOption.exact)` for record counting scenarios.
