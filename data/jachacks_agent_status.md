# Jachacks non-SF repo repair status

Checker: `/home/jac/.local/bin/jac.bak-0.36.1 check -j 8 <REPO>` under jac 0.36.1 (strict static checker).
Run from `/home/jac/repos/jac_llm_data/data/jachacks_nonsf`. All repos were repaired in place so a separate
process can harvest green repos and rebuild the dataset.

## Results — all 8 repos GREEN (0 errors; warnings only)

| Repo | Final result | Warnings |
|---|---|---|
| Dhravidk__TraceForge | 19 passed | yes |
| Matusvec__spatialMind_JAC | 24 passed | yes |
| yousefalwahami__rent_jac | 24 passed | yes |
| Async-Avengers__repoGhost | 52 passed | yes |
| justinhh4__Binsight | 21 passed | yes |
| ayushmk7__GhostWatch | 63 passed | yes |
| krishs09-123__jachacks-engagement-auditor | 41 passed | yes |
| Anay162__agewise | 264 passed | yes |

## Notable repairs per repo

- **Dhravidk__TraceForge** — migrated `import:py`/`can`/`has` dialect, fixed old edge/visit syntax, typed graph
  ops. Files: `main.jac`, `tests/smoke.jac`, `traceforge/*.jac`.
- **Matusvec__spatialMind_JAC** — repaired examples under `.planning/research/jac-docs` (old `can`/edge syntax)
  plus `services/py_bridge.jac`.
- **yousefalwahami__rent_jac** — typed JSX conditionals (`str(...)`), `any` for `JSON.parse`/`localStorage`,
  `Unit | None` guards for optional graph nodes, typed vendor pools, env fallbacks. Files: `workflow.jac`,
  `tenants_properties.jac`, `services/{foursquare,appService}.jac`, `services/graph/{crud,triage}.jac`,
  `index.jac`.
- **Async-Avengers__repoGhost** — removed `import from typing { Any }` (use builtin `any`), converted Python
  lambdas to `lambda (x) -> T {}`, backtick-escaped `` `match `` (re import), replaced `flow`/`Future`/`wait`
  with synchronous calls (jac 0.36.1 types `flow f()` as T, not `Future[T]`, and E1308 sendability rejects
  mutable values), fixed callback arity. Files: `app/orchestration/workflow.jac`, `app/ui/WidgetShell.jac`, etc.
- **justinhh4__Binsight** — mass-fixed malformed edge filters `[-->][?:T)` → `[-->][?:T]`, reordered `has`
  fields (required before defaulted), fixed lambda closures, annotated seed dicts, escaped `match` ability.
  Files: `binsight/jac_app/extensions/domain/*`, `extensions/walkers/*.jac`.
- **ayushmk7__GhostWatch** — dialect migration throughout (old `can`/`has`/`visit`, imports, casts).
- **krishs09-123__jachacks-engagement-auditor** — replaced `typing.Any` with `any`; renamed `.sv.jac` service
  modules to `.jac` (module resolution); added `await` to async hook calls (`useProjects`, `useAuditRun`);
  cast graph-connection results (`created[0] as Project`); fixed E5082 client-presence issues; fixed Unknown
  cascades in `services/heuristics.jac`.
- **Anay162__agewise** — largest repair (57 → 0 failures):
  - `components/layout.jac`: replaced unsupported `<@item["icon"]/>` dynamic JSX tag with `NavItem` helper
    component using a capitalized local (`Icon = item["icon"]; <Icon/>`).
  - `pages/*.jac`: bare specifiers `components.X`/`client.X`/`graph.walkers.*` are not client-reachable —
    converted to relative `..` imports (E5084). JS `.length` → `len()`. Spawn results annotated `any`.
  - CSS-string `style` props → `style={_css(...)}` via per-file `_css()` helper returning `dict[str, object]`
    (intrinsic prop requires dict); `onClick`/`href` props fixed via `any` annotations/`.get(...,"")`.
  - Reserved-word escapes: `` `report `` has-field, `` `entry `` var (renamed `rec`), `` `match `` re import.
  - Node-field fixes: renamed stale accesses (`txn.merchant`→`merchant_name`, `txn.transaction_date`→`date`,
    `RecurringBill.expected_amount`→`average_amount`, `last_paid_date`→`last_payment_date`,
    `Dispute.error_description`→`description`, ScamAlert kwargs `alert_type`→`threat_type`,
    `detected_date`→`detected_at`); added missing `has` fields (`Appointment.provider_phone`,
    `Dispute.payer_name`, `Notification.reference_id`).
  - Walkers using dynamic `self.x` fields now declare `has` (`today`, `alerts`, `flagged`, `patient`,
    `current_claim`, `active_policies`, `patient_name`, `current_insurer*`, `patient_ref`).
  - Unmangled 16 sites of `[__n for __n in [v for v in [...] if isinstance(__n,T)] ...]` comprehensions;
    fixed `[<--here]`/`[here<---->]` edge refs.
  - Structural fixes: missing `}` appended (ncci_mue/ncci_ptp/push_client), `except { }` → `except Exception`,
    docstring-statement `;`, removed illegal `global`, explicit `self:` param removed, `node` param renamed
    (`nd`), `try`/`if` brace imbalance in deadline_tracker.
  - Missing trigger-type imports added (Claim, LineItem, FinancialAccount, Insurer).
  - Unresolved third-party modules (playwright/httpx/plaid/imap `email` payload) — annotated roots
    `with (Client() as any) as c`, `msg: any`, `_get_plaid_client() -> any`, `_txn_to_dict(t: any)`,
    `patient: any`; note a checker quirk: `while` inside `with` re-loses the binding type — worked around
    with `cc: any = c` before the loop (blue_button_client).

## Known non-blocking warnings

- W1100 unresolved imports for uninstalled third-party packages (plaid, playwright, httpx, bland, vapi,
  firebase_admin, twilio, etc.) and npm `lucide-react`/`react-router-dom` (no jac.toml deps declared).
- "preferred native but did not lower; compiled in the server codespace" notes on several walkers
  (`datetime.utcnow`, `strptime`, `in` over `any`) — informational, not errors.
