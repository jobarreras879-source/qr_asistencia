
## 2024-05-29 - CountOption in Supabase Flutter
**Learning:** In `supabase_flutter` v2+, you can directly chain `count(CountOption.exact)` in queries to get a `PostgrestFilterBuilder<int>` and avoid downloading data when only the count is needed, returning a Future<int>.
**Action:** Use `.count(CountOption.exact)` instead of `.select()` and local `.length` counting when needing just the count of matching rows to save memory footprint and latency.
