## 2024-05-18 - Avoid loading all data for counts in Supabase
**Learning:** Using `.select()` and then getting `.length` in memory downloads the entire matching dataset to the client, which can be a severe bottleneck for large tables.
**Action:** Use `.count(CountOption.exact)` with `supabase_flutter` to execute a fast COUNT query on the server and return an integer directly.
