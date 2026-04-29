## $(date +%Y-%m-%d) - Supabase Counting Optimization
**Learning:** In Supabase, using `.select()` just to count rows downloads and parses all matching records, causing unnecessary network and memory overhead. Using `.count(CountOption.exact)` efficiently pushes the count operation to the database.
**Action:** When only the total number of matching rows is needed from a Supabase query, always use `.count(CountOption.exact)` rather than `.select()` followed by calculating `.length` on the client.
