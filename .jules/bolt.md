## 2024-05-18 - Supabase count vs select
**Learning:** In Supabase flutter v2+, calling `.count(CountOption.exact)` directly returns a `Future<int>` instead of a full PostgrestResponse object, making it much more efficient for counting records without downloading data to the client.
**Action:** When querying Supabase just to get the number of matching rows, always use `.count(CountOption.exact)` instead of `.select()` to avoid network and memory overhead of downloading and parsing full objects.
