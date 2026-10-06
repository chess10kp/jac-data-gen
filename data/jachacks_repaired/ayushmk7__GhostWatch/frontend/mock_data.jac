glob:pub DEMO_MODE: bool = True;

glob:pub LANDING_FEATURES: list[dict[str, str]] = [
         {
             "title": "Graph-native awareness",
             "body": "GhostWatch treats the repository as topology, not a folder list, so review context feels spatial instead of isolated.",
             "kind": "graph",
             "delay": "gw-stagger-2"
         },
         {
             "title": "Specialist walker verdicts",
             "body": "Security, compatibility, and blast-radius perspectives stay distinct, visible, and composable instead of melting into one vague answer.",
             "kind": "walkers",
             "delay": "gw-stagger-3"
         },
         {
             "title": "Maintainer-first control",
             "body": "Automation moves fast, but human approval remains legible, central, and calm inside the control room.",
             "kind": "shield",
             "delay": "gw-stagger-4"
         }
     ];

glob:pub FLOW_STEPS: list[dict[str, str]] = [
         {
             "step": "01",
             "title": "Detect",
             "body": "Spot pull request movement or manifest drift before the change disappears into the background.",
             "delay": "gw-stagger-2"
         },
         {
             "step": "02",
             "title": "Traverse",
             "body": "Move through connected files and dependency paths with topology-aware context.",
             "delay": "gw-stagger-3"
         },
         {
             "step": "03",
             "title": "Score",
             "body": "Translate structural impact into a risk surface that stays understandable at a glance.",
             "delay": "gw-stagger-4"
         },
         {
             "step": "04",
             "title": "Escalate",
             "body": "Surface the right severity to maintainers without turning the interface into an alarm storm.",
             "delay": "gw-stagger-5"
         },
         {
             "step": "05",
             "title": "Prepare Fix",
             "body": "Keep the UI ready for auto-fix evidence, branch context, and merge handoff the moment it is available.",
             "delay": "gw-stagger-6"
         }
     ];

glob:pub SIDEBAR_ITEMS: list[dict[str, str]] = [
         {"label": "Overview", "meta": "Defense desk snapshot"},
         {"label": "PR Review", "meta": "PRs under watch"},
         {"label": "Dependency Alerts", "meta": "Manifest & supply chain"},
         {"label": "Incidents", "meta": "Escalation feed"},
         {"label": "Settings", "meta": "Desk & repositories"}
     ];

glob:pub SUMMARY_CARDS: list[dict[str, str]] = [
         {
             "label": "Open PRs (linked repo)",
             "value": "12",
             "delta": "+2 today",
             "tone": "frost",
             "spark": "6,30 42,18 80,20 122,10 160,16 198,8 236,14 274,9"
         },
         {
             "label": "Critical Findings",
             "value": "03",
             "delta": "1 path cooling",
             "tone": "cyan",
             "spark": "6,34 42,32 80,24 122,28 160,14 198,18 236,12 274,10"
         },
         {
             "label": "Dependency Drift",
             "value": "07",
             "delta": "2 unresolved",
             "tone": "aqua",
             "spark": "6,28 42,20 80,22 122,14 160,18 198,12 236,16 274,11"
         },
         {
             "label": "Review Throughput",
             "value": "94%",
             "delta": "median stable",
             "tone": "amber",
             "spark": "6,36 42,26 80,24 122,20 160,18 198,15 236,11 274,10"
         }
     ];

glob:pub INCIDENTS: list[dict[str, str]] = [
         {
             "time": "14:02",
             "severity": "critical",
             "title": "Suspicious manifest delta",
             "detail": "A runtime package appeared without an import trail across the watched subgraph.",
             "hint": "Inspect manifest drift"
         },
         {
             "time": "13:44",
             "severity": "high",
             "title": "High-risk PR path touched",
             "detail": "A core auth boundary changed near configuration loading and transport code.",
             "hint": "Trace blast radius"
         },
         {
             "time": "13:08",
             "severity": "medium",
             "title": "Auto-fix branch prepared",
             "detail": "The demo pipeline staged a clean manifest candidate and attached evidence notes.",
             "hint": "Open review handoff"
         }
     ];

glob:pub WALKER_STATUS: list[dict[str, str]] = [
         {"name": "Security Auditor", "state": "Active"},
         {"name": "Compatibility Checker", "state": "Queued"},
         {"name": "Blast Radius Mapper", "state": "Watching"}
     ];

glob:pub ATTENTION_ITEMS: list[dict[str, str]] = [
         {"title": "Maintainer approvals pending", "value": "2 pending"},
         {"title": "Dependency lockfile mismatch", "value": "1 unresolved"},
         {"title": "Comments ready to post", "value": "4 prepared"}
     ];

glob:pub MAINTAINER_PR_REVIEW_ROWS: list[dict[str, str]] = [
         {
             "pr": "#612",
             "title": "Harden client spawn retry + backoff",
             "author": "@dev-a",
             "risk": "High",
             "status": "Checks running"
         },
         {
             "pr": "#608",
             "title": "Theme token bump for glass panels",
             "author": "@dev-b",
             "risk": "Low",
             "status": "Approved"
         },
         {
             "pr": "#601",
             "title": "Walker manifest diff — new runtime dep",
             "author": "@dev-c",
             "risk": "Critical",
             "status": "Needs maintainer"
         }
     ];

glob:pub MAINTAINER_DEPENDENCY_ROWS: list[dict[str, str]] = [
         {
             "package": "esbuild",
             "change": "0.19.x → 0.21.x",
             "severity": "Medium",
             "note": "Lockfile mismatch vs package.json"
         },
         {
             "package": "openssl (transitive)",
             "change": "CVE advisory chain",
             "severity": "High",
             "note": "Awaiting upstream patch window"
         },
         {
             "package": "internal graph-sdk",
             "change": "Unpinned git ref",
             "severity": "Low",
             "note": "Pin to tagged release before merge"
         }
     ];

glob:pub MAINTAINER_WATCHED_REPOS: list[dict[str, str]] = [
         {
             "slug": "jaseci-labs/jaseci",
             "role": "Lead maintainer",
             "branch": "main",
             "pinned": "true"
         },
         {
             "slug": "jaseci-labs/jaclang",
             "role": "Maintainer",
             "branch": "main",
             "pinned": "false"
         }
     ];

glob:pub CONTRIBUTOR_SIDEBAR_ITEMS: list[dict[str, str]] = [
         {"label": "Overview", "meta": "Repository snapshot"},
         {"label": "Suggestions", "meta": "Issues and AI picks"},
         {"label": "Docs & tests", "meta": "Coverage and gaps"},
         {"label": "Activity", "meta": "Recent merges"},
         {"label": "Settings", "meta": "Account and repos"}
     ];

glob:pub CONTRIBUTOR_GITHUB_ISSUES: list[dict[str, str]] = [
         {
             "id": "412",
             "title": "Flaky walker integration test on CI",
             "labels": "testing, ci",
             "state": "Open"
         },
         {
             "id": "401",
             "title": "Document jac-client spawn timeout behavior",
             "labels": "documentation",
             "state": "Open"
         },
         {
             "id": "388",
             "title": "Reduce bundle size for dashboard chunk",
             "labels": "performance",
             "state": "Open"
         }
     ];

glob:pub CONTRIBUTOR_AI_ISSUES: list[dict[str, str]] = [
         {
             "id": "AI-1",
             "title": "Add regression test for graph export path",
             "reason": "Touches untested serialization branch"
         },
         {
             "id": "AI-2",
             "title": "Expand API error table in operator guide",
             "reason": "New status codes shipped without examples"
         },
         {
             "id": "AI-3",
             "title": "Refactor duplicate validation in signup form",
             "reason": "Small safe cleanup with high readability win"
         }
     ];

glob:pub CONTRIBUTOR_DOCS_ROWS: list[dict[str, str]] = [
         {
             "path": "docs/contributing.md",
             "status": "Last updated 6d ago",
             "note": "Install steps match current CLI"
         },
         {
             "path": "docs/architecture/overview.md",
             "status": "Stale section flagged",
             "note": "Walker lifecycle diagram references retired module"
         },
         {"path": "README.md", "status": "OK", "note": "Badge links resolve"}
     ];

glob:pub CONTRIBUTOR_TEST_ROWS: list[dict[str, str]] = [
         {
             "suite": "jac-client/router",
             "status": "Missing branch coverage",
             "note": "No test for nested dynamic segments"
         },
         {
             "suite": "components/AppShell",
             "status": "Snapshot only",
             "note": "Add interaction test for sidebar"
         },
         {
             "suite": "walkers/gap_analysis",
             "status": "Green",
             "note": "Core paths covered in integration run"
         }
     ];

glob:pub CONTRIBUTOR_ACTIVITY_ROWS: list[dict[str, str]] = [
         {"when": "2h ago", "what": "Merge PR #612 — fix client spawn retry"},
         {"when": "Yesterday", "what": "Opened draft PR — docs table styles"},
         {"when": "Mon", "what": "Pushed — chore: bump theme tokens"}
     ];

glob:pub CONTRIBUTOR_SAVED_REPOS: list[dict[str, str]] = [
         {"slug": "jaseci-labs/jaseci", "role": "Contributor", "pinned": "true"},
         {"slug": "jaseci-labs/jaclang", "role": "Contributor", "pinned": "false"}
     ];

glob:pub CONTRIBUTOR_SUMMARY_CARDS: list[dict[str, str]] = [
         {
             "label": "Open issues (linked repo)",
             "value": "05",
             "delta": "from latest gap run",
             "tone": "frost",
             "spark": "6,32 42,22 80,18 122,24 160,12 198,16 236,14 274,10"
         },
         {
             "label": "Untested paths",
             "value": "08",
             "delta": "3 quick wins",
             "tone": "cyan",
             "spark": "6,30 42,28 80,20 122,26 160,16 198,14 236,12 274,11"
         },
         {
             "label": "Docs gaps",
             "value": "04",
             "delta": "Jac modules noted",
             "tone": "aqua",
             "spark": "6,26 42,22 80,24 122,18 160,20 198,11 236,14 274,9"
         },
         {
             "label": "Merge velocity",
             "value": "72%",
             "delta": "rolling window",
             "tone": "amber",
             "spark": "6,34 42,24 80,22 122,18 160,20 198,13 236,10 274,12"
         }
     ];

glob:pub CONTRIBUTOR_WALKER_STATUS: list[dict[str, str]] = [
         {"name": "GapAnalysisWalker", "state": "Watching"},
         {"name": "Graph doc linker", "state": "Queued"},
         {"name": "Contributor ranker", "state": "Active"}
     ];

glob:pub CONTRIBUTOR_ATTENTION_ITEMS: list[dict[str, str]] = [
         {"title": "Suggestions ready to pick up", "value": "3 open"},
         {"title": "Docs requested for PR #184", "value": "1 thread"},
         {"title": "Merge follow-ups", "value": "2 notes"}
     ];

glob:pub DEMO_PR_URL: str = "https://github.com/ayushmk7/GhostWatch/pull/1";
glob:pub DEMO_REPO_URL: str = "https://github.com/ayushmk7/GhostWatch";

glob:pub CLAUDE_JASECI_CONTEXT_PARAS: list[str] = [
         (
             "The official Jaseci monorepo hosts the Jac stack: jaclang (Jac to Python bytecode, JavaScript, and native code), "
             "byllm for LLM integration, jac-client for full-stack apps with the npm/Vite ecosystem, jac-scale for deployment "
             "(FastAPI, Redis, MongoDB, Kubernetes), jac-super, and jac-mcp. The convenience bundle installs with pip install jaseci."
         ),
         (
             "Jac emphasizes AI-native Meaning Typed Programming, building backend and frontend in one language, graph-native domain "
             "modeling with walkers, and cloud-style serving via jac start (with optional scaling flags). Documentation, tutorials, "
             "and contribution guidelines live in the same repository."
         ),
         (
             "GhostWatch scopes this demo to jaseci-labs/jaseci; GraphStateWalker streams open issues (capped at 100) and a TTL-cached Anthropic digest for maintainer triage."
         )
     ];
