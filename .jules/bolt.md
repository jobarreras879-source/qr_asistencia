## 2024-05-30 - Network Bottlenecks in Sync Operations
**Learning:** Google Sheets API calls inside of a loop (e.g., synchronizing a local database of records) result in a severe N+1 HTTP request bottleneck, which limits throughput and risks hitting rate limits.
**Action:** Always prefer batch operations via APIs that support them. For `googleapis/sheets`, use `ValueRange` populated with a `List<List<Object?>>` and `sheetsApi.spreadsheets.values.append` to send all rows in a single network request.
