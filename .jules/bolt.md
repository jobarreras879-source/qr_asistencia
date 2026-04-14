## 2024-11-20 - [Supabase Counting Queries]
**Learning:** [When querying Supabase just to get the number of matching rows, `.count(CountOption.exact)` avoids downloading all matching records to the client and parsing them into Dart structures compared to using `.select()`, which parses the entire list to just get `.length`.]
**Action:** [Use `.count(CountOption.exact)` for row counts to reduce network overhead and parsing time instead of `.select()` and returning `.length`.]
