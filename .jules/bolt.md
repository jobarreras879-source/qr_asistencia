## 2024-05-18 - Google Sheets Batch Insert
**Learning:** In Google Sheets integrations (`googleapis/sheets/v4.dart`), sequentially calling `sheetsApi.spreadsheets.values.append` inside a `for` loop (N+1 queries) severely limits data synchronization performance.
**Action:** When performing bulk row insertions, populate a `ValueRange` with a `List<List<Object?>>` representing multiple rows and execute a single `append` call (with `insertDataOption: 'INSERT_ROWS'`) to minimize network roundtrips.
