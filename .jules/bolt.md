## 2024-10-24 - Supabase count vs select
**Learning:** Querying Supabase with `.select()` and parsing the result to get its `.length` downloads all matching rows to the client, converting them into Dart maps unnecessarily, which can be expensive.
**Action:** When only the row count is needed, use `.count(CountOption.exact)` instead. In supabase_flutter v2+, it returns a PostgrestFilterBuilder<int> which allows chaining methods like `.gte()` and `.eq()` directly on it, before awaiting to get the final integer.
