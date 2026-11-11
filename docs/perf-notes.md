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

## HTTP-edge measurement (FL9, 2026-11-11)

**Tool:** `scripts/perf-seed.sh` (bash + curl + jq, fake-auth only). It seeds through the public API and times the read endpoints with curl (`time_total`, so the network stack is included; 25 calls each). **Dataset:** 100 small groups (3 members, 5 expenses each) plus one group with 15 members, 500 expenses (a third EQUAL, a third multi-payer, a third EXACT) and 200 settlements; the database then held 151 groups, 1 174 expenses, 3 499 splits and 221 settlements. Backend: local jar, dev profile, PostgreSQL 16 in Docker on the same machine; one client, no concurrency.

| Endpoint | p50 ms | p95 ms | max ms |
|:--|--:|--:|--:|
| GET /groups (list) | 14.4 | 16.9 | 20.2 |
| GET /groups/{gid} | 14.6 | 19.1 | 32.7 |
| GET expenses page 0 (20) | 19.3 | 22.5 | 22.9 |
| GET expenses last page (page 24) | 18.3 | 21.7 | 28.4 |
| GET expense detail | 12.4 | 15.2 | 21.2 |
| GET expense revisions | 8.8 | 11.1 | 84.0 |
| GET balances | 16.5 | 18.6 | 20.0 |
| GET settlements (page 0) | 9.9 | 11.7 | 13.6 |

**Reading**
- Every p95 is far below the spec target of 500 ms. The last expense page costs the same as the first: the list is served by `ix_expenses_group_list`.
- The multi-group case (open point below) is now **partly** measured: 100 other groups in the database did not change any endpoint. `EXPLAIN (ANALYZE, BUFFERS)` of the expense list query for the 500-expense group: `Index Only Scan using ix_expenses_group_list`, 13 buffer hits, 0.15 ms execution (planning 1.7 ms). The balances statement was **not** re-explained on this data.
- Not measured: concurrent clients (the sizing section above rests on the in-process tests), a database with about 1 000 groups, a remote client on a mobile network.
- **Re-run:** `BASE_URL=http://localhost:18080 OTHER_GROUPS=100 bash scripts/perf-seed.sh` (about 4 minutes; `EXPENSES`, `MEMBERS`, `SETTLEMENTS`, `CALLS` are variables).

## Open points
- Repeat the measurement with many groups in the same database: 100 extra groups were measured at the HTTP edge (no effect); 1 000 groups of the same size are still not measured.
- `count(*)` for list pagination and the group totals are O(group size); fine at ~500 rows per group.
