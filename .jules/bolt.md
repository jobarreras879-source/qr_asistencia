## 2024-05-18 - Avoid fetching data just to count rows with Supabase
**Learning:** Using `select()` just to find the size of a list by calling `.length` is a common performance bottleneck because it downloads all the rows over the network, parses them into Dart objects, and allocates memory for a list that is only used to compute its length.
**Action:** Use `.count(CountOption.exact)` (which returns `Future<int>`) instead of `.select()` when only the total number of matching rows is needed.
