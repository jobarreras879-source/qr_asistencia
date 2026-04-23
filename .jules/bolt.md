## 2024-06-25 - Batch Operations & Formula Injection in Sheets

**Learning:** The GoogleDriveService implementation was executing individual `append` network requests for each row during the sync operation inside `SheetsConfigScreen`. With many records, this N+1 operation behavior causes severe delays, API rate limit potential, and a poor UI block. In addition, user input intended for Google Sheets is susceptible to formula injection if text begins with `=`, `+`, `-`, or `@`.

**Action:** Replace single-row iterative network calls (`appendAttendanceRow`) with a batched alternative (`batchAppendAttendanceRows`) utilizing a single `ValueRange` payload containing a `List<List<Object>>`. Ensure all data strings dynamically pushed into a Google Sheet cell that begin with calculation markers are preemptively escaped with a single quote (`'`) to treat the input explicitly as text, reducing both latency and formula injection risks.
