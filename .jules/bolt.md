## 2024-05-18 - Supabase Row Counting
**Learning:** Using `.select('fecha_hora')` to count rows in `AttendanceService.getTodayCount` is a performance anti-pattern that forces Supabase to download all matching rows and Dart to parse them into memory, wasting bandwidth and memory.
**Action:** Always use `.count(CountOption.exact)` on the Supabase builder when only the number of matching rows is needed.
