## 2024-05-11 - Use Supabase Count
**Learning:** Using `.select()` just to get the length of an array is inefficient, particularly with Supabase where downloading all rows adds network and parsing overhead.
**Action:** Use `.count(CountOption.exact)` to offload the counting logic to the database and retrieve only a single integer.
