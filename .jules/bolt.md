## 2024-05-24 - Supabase count vs select
**Learning:** In Supabase, fetching records using `.select()` when only the total number is needed pulls full data objects over the network and requires allocating memory for client-side collections. This adds unnecessary parsing and network overhead.
**Action:** Always prefer `.count(CountOption.exact)` for record tallying logic to execute a lightweight `COUNT(*)` natively on the database server.
