## 2024-04-06 - [Supabase Count Optimization]
**Learning:** Using `.select()` to fetch records and `.length` in Dart to count rows is highly inefficient due to unnecessary network payload and client-side memory allocation.
**Action:** Use `.count(CountOption.exact)` to push the counting operation to the database and return only an integer.
