
## 2024-05-18 - [Batch Append for Google Sheets API]
**Learning:** Appending rows one-by-one to Google Sheets in a loop causes severe network overhead (N+1 query problem). The `googleapis` library supports bulk insertion via `sheetsApi.spreadsheets.values.append` when populated with a `List<List<Object?>>` in `ValueRange`.
**Action:** Always use batch operations when syncing collections to external services to optimize performance and reduce request bottlenecks.
