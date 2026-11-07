# Performance notes

Evidence from `EXPLAIN (ANALYZE, BUFFERS)` on PostgreSQL 16 (Testcontainers), produced by `BalancesPerformanceIT` (full output is written to `backend/target/perf-balances-explain.txt` on every `./mvnw verify`). Earlier list-query evidence is in `docs/gates/review-cp2.md` section 5.

## B7: balances and settlements

**Dataset:** one group with 15 members, 500 expenses (1 payer + 3 participants each), 200 settlements, generated in SQL; tables `ANALYZE`d.
**Planned maximum:** the same numbers (spec/B7 prompt). Expected real load is far lower (one organizer, a trip).

| Query | Plan | Execution |
|:--|:--|:--|
| `GET /balances`: one grouped statement (payers + splits of live expenses, settlements from/to, `UNION ALL`, `GROUP BY member_id`) | Hash joins of `expense_payers` / `expense_splits` with the group's live `expenses`, two scans of `settlements`, `HashAggregate` → 15 rows; 44 buffer hits | 2.1 ms (planning 1.1 ms) |
| Whole request `GET /balances` (MockMvc, warm) | group lookup + member list (2 JPA statements) + the one totals statement | 23 ms, bound asserted: < 2000 ms |
| Settlements list page | `Index Scan using ix_settlements_group_list` + `Limit`, 3 buffers | 0.05 ms |
| Settlements count | seq scan of the group's rows (4 buffers) | 0.07 ms |
| Member-in-settlement check (delete-member rule) | `Limit 1` over a seq scan | 0.02 ms |

**Reading**
- The balances cost grows with the number of members, not with rows shipped to Java: the database returns 15 rows. All of it is two hash joins over a few hundred to a few thousand rows.
- The planner chose sequential scans on `expenses`, `expense_payers`, `expense_splits` and `settlements` because in this test the group *is* nearly the whole table and the tables span a handful of pages. That is the right choice at this size; with many groups in the database the partial index `ix_expenses_group_list`, `ix_expenses_group` and `ix_settlements_group_list` are what let it read only the group's range. This multi-group case was **not** measured (hypothesis).
- **No new index is justified by this evidence.** The indexes added in V8 (`ix_settlements_group_list`, `ix_settlements_group`, `ix_settlements_from_member`, `ix_settlements_to_member`) serve the list/delete-rule queries by design; the planner already uses the first for the page query. The two member indexes are not exercised at this size (the `OR` check is a 0.02 ms seq scan); they matter once the settlements table is large.
- Consistency: the statement is a single snapshot, and the service runs it in a read-only `REPEATABLE READ` transaction together with the roster read; `BalancesSettlementsIT` reads balances while 4 writers create expenses and settlements and every response sums to 0.

**How to re-run:** `cd backend && ./mvnw -o verify -Dit.test=BalancesPerformanceIT -Dtest=NoSuchTest -Dsurefire.failIfNoSpecifiedTests=false`.

## B8: sizing for one small VPS, p95, remaining queries

**Assumed host:** 2 vCPU / 2 GB RAM shared by PostgreSQL, the backend and Caddy (`docker-compose.prod.yml` limits: db 512 MB, backend 768 MB, caddy 128 MB).

| Setting | Value | Why |
|:--|:--|:--|
| Hikari `maximum-pool-size` / `minimum-idle` | 10 / 2 | Typical requests take 1-50 ms of database time (below), so 10 connections serve well over 100 requests/second; more connections only add contention on 2 vCPU. PostgreSQL `max_connections=30` leaves room for the backup job and admin sessions. |
| Hikari `connection-timeout` | 5 s | A saturated pool answers an error quickly instead of hanging the app. `leak-detection-threshold` 20 s logs a held connection. |
| Tomcat `threads.max` | 50 | More request threads than connections is intended (threads wait briefly for a connection); more would only queue memory. |
| JVM | `MaxRAMPercentage=65`, `-Xss512k`, `ExitOnOutOfMemoryError` | About 500 MB heap in the 768 MB container; observed resident memory 337 MiB right after start-up with the production profile. |
| Request limits | body 64 KB, header 16 KB, amounts ≤ 10^12, lists ≤ 100 | Bounds the work any single request can cause. |

**Typical request time on the maximum dataset** (15 members, 500 expenses, 200 settlements; `BalancesPerformanceIT`, 25 calls each, in-process so network time is excluded; spec target p95 < 500 ms):

| Request | p95 |
|:--|:--|
| group list / group detail | 13 ms / 27 ms |
| expense list (20) / expense detail | 46 ms / 32 ms |
| revisions / settlements list | 16 ms / 18 ms |
| balances / preview | 22 ms / 15 ms |

**Remaining queries, EXPLAIN on the same dataset** (all indexed; full output in `backend/target/perf-balances-explain.txt`): members of a group (`ux_members_group_name`, 0.16 ms), group summaries (owner index, member count via the same index, expense sums are a scan of the group's rows because the group is the whole table here, 1.0 ms), revisions of an expense (`ux_expense_revisions_version`), member-in-settlement check (0.02 ms).

**Statements per request do not grow with the data** (`ExpenseListQueryCountIT`): expense list 6 (8 when the page has itemized bills), settlement list 3, revisions ≤ 3, group detail ≤ 4, group list 2, balances 2 JPA statements plus the one totals statement.

## Open points
- Repeat the measurement with many groups in the same database (e.g. 1 000 groups of the same size) before relying on the index behaviour at scale.
- `count(*)` for list pagination and the group totals are O(group size); fine at ~500 rows per group.
