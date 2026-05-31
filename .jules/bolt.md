
## 2024-05-18 - Avoid downloading rows for counting in Supabase
**Learning:** When querying Supabase to get the number of matching rows, `.select()` downloads all matching records to the client. This wastes memory and bandwidth.
**Action:** Use `.count(CountOption.exact)` on the Postgrest query builder instead to let the database do the counting, which returns just the integer count.
