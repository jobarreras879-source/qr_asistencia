## 2024-05-18 - [Optimize Supabase Count Queries]
**Learning:** Fetching all rows using `select('fecha_hora')` just to count the length of the resulting array in Dart causes unnecessary network data transfer and JSON parsing overhead, especially as the number of records grows.
**Action:** Use Supabase's built-in `.count(CountOption.exact)` modifier on queries where only the number of rows is needed, allowing the database engine to perform the count and return a single integer to the client.
