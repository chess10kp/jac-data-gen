import from "@jac/runtime" { Link }
import from .AmbientBackground { AmbientBackground }
import from .GhostWatchWordmark { GhostWatchWordmark }
import from .SidebarNavButton { SidebarNavButton }
import from .SummaryCard { SummaryCard }
import from .GraphPlaceholderAccent { GraphPlaceholderAccent }
import from .WalkerStatusItem { WalkerStatusItem }
import from .AttentionItem { AttentionItem }
import from .GraphView { GraphView }
import from ..mock_data {
    SIDEBAR_ITEMS,
    INCIDENTS,
    CONTRIBUTOR_SIDEBAR_ITEMS,
    CONTRIBUTOR_GITHUB_ISSUES,
    CONTRIBUTOR_AI_ISSUES,
    CONTRIBUTOR_DOCS_ROWS,
    CONTRIBUTOR_TEST_ROWS,
    CONTRIBUTOR_ACTIVITY_ROWS,
    CONTRIBUTOR_SAVED_REPOS,
    MAINTAINER_PR_REVIEW_ROWS,
    MAINTAINER_DEPENDENCY_ROWS,
    MAINTAINER_WATCHED_REPOS,
    DEMO_PR_URL,
    DEMO_REPO_URL
}

def doFetch(url: str, opts: dict) -> any {
    return fetch(url, opts);
}

def parse_repo_slug(raw: str) -> str {
    t = raw.strip();
    t = t.replace("https://github.com/", "");
    t = t.replace("http://github.com/", "");
    t = t.replace("github.com/", "");
    t = t.strip().strip("/");
    return t if t else "unknown/repo";
}

def parse_pr_ref(raw: str) -> str {
    t = str(raw or "").strip();
    if not t {
        return "—";
    }
    parts = t.rstrip("/").split("/");
    if len(parts) == 0 {
        return t;
    }
    return "#" + str(parts[len(parts) - 1]);
}

def path_key(raw: str) -> str {
    t = str(raw or "").strip().lower();
    if not t {
        return "";
    }
    parts = t.split("/");
    name = parts[len(parts) - 1] if len(parts) > 0 else t;
    name = name.replace(".jac", "");
    name = name.replace(".py", "");
    name = name.replace(".tsx", "");
    name = name.replace(".ts", "");
    name = name.replace(".jsx", "");
    name = name.replace(".js", "");
    name = name.replace(".md", "");
    return name;
}

def contains_text(haystack: str, needle: str) -> bool {
    h = str(haystack or "");
    n = str(needle or "");
    if not n {
        return False;
    }
    return h.find(n) >= 0;
}

def looks_like_doc(raw: str) -> bool {
    t = str(raw or "").strip().lower();
    if not t {
        return False;
    }
    return t.endswith(".md") or contains_text(t, "/docs/") or t.startswith("docs/");
}

def str_or(val: any, fallback: str) -> str {
    if not val {
        return fallback;
    }
    return str(val);
}

def safeLen(val: any) -> int {
    if not val {
        return 0;
    }
    if not Array.isArray(val) {
        return 0;
    }  # jac:ignore[E1032]
    return len(val);
}

def:pub AppShell(mode: str) -> JsxElement {
    isContributor = mode == "contributor";
    has activeSection: str = "Overview",
        repoDisplay: str = parse_repo_slug(DEMO_REPO_URL),
        graphState: dict | None = None,
        graphFetchError: str = "",
        analysisLoading: bool = False,
        analysisResult: dict | None = None,
        animatingPath: list = [];

    async def fetchGraphState() -> None {
        try {
            res: any = await doFetch(
                "/walker/GraphStateProxy",
                {
                    "method": "POST",
                    "headers": {"Content-Type": "application/json"},
                    "body": "{}"
                }
            );
            if not res.ok {  # jac:ignore[E1032]
                graphState = None;  # jac:ignore[E1001]
                graphFetchError = "graph proxy returned " + str(res.status);  # jac:ignore[E1001,E1032]
                return;
            }
            data: any = await res.json();  # jac:ignore[E1032]
            reports: any = (data["data"] or {})["reports"] or [];  # jac:ignore[E1001]
            if len(reports) > 0 {  # jac:ignore[E1053]
                graphState = reports[0];  # jac:ignore[E1001]
                if reports[0]["demo_repo_slug"] {
                    repoDisplay = str(reports[0]["demo_repo_slug"]);  # jac:ignore[E1001]
                }
                graphFetchError = "";  # jac:ignore[E1001]
            } else {
                graphState = None;  # jac:ignore[E1001]
                graphFetchError = "proxy returned 0 reports";  # jac:ignore[E1001]
            }
        } except Exception as e {  # jac:ignore[W2052]
            graphState = None;  # jac:ignore[E1001]
            graphFetchError = str(e);  # jac:ignore[E1001]
        }
    }

    async def runAnalysis() -> None {
        analysisLoading = True;  # jac:ignore[E1001]
        analysisResult = None;  # jac:ignore[E1001]
        animatingPath = [];  # jac:ignore[E1001]

        try {
            body_str: any = JSON.stringify({"pr_url": DEMO_PR_URL});  # jac:ignore[E1032]
            res: any = await doFetch(
                "/walker/OrchestratorProxy",
                {
                    "method": "POST",
                    "headers": {"Content-Type": "application/json"},
                    "body": body_str
                }
            );
            if not res.ok {  # jac:ignore[E1032]
                graphFetchError = "analysis proxy returned " + str(res.status);  # jac:ignore[E1001,E1032]
                return;
            }
            data: any = await res.json();  # jac:ignore[E1032]
            reports: any = (data["data"] or {})["reports"] or [];  # jac:ignore[E1001]

            if len(reports) > 0 {  # jac:ignore[E1053]
                result: any = reports[0];  # jac:ignore[E1001]
                analysisResult = result;  # jac:ignore[E1001]
                paths: any = result["traversal_paths"] or {};  # jac:ignore[E1001]
                blast_path: any = paths["blast_radius"] or [];  # jac:ignore[E1001]
                animatingPath = blast_path;  # jac:ignore[E1001]
                graphFetchError = "";  # jac:ignore[E1001]
            } else {
                graphFetchError = "analysis proxy returned 0 reports";  # jac:ignore[E1001]
            }
        } except Exception as e {  # jac:ignore[W2052]
            graphFetchError = str(e);  # jac:ignore[E1001]
        } finally {
            analysisLoading = False;  # jac:ignore[E1001]
        }
        await fetchGraphState();
    }

    async can with entry {
        await fetchGraphState();
    }

    sidebarItems = CONTRIBUTOR_SIDEBAR_ITEMS if isContributor else SIDEBAR_ITEMS;

    live_nodes: list = graphState["nodes"] if graphState else [];
    live_edges: list = graphState["edges"] if graphState else [];
    high_risk_count: int = len(
        [
            n
            for n in live_nodes
            if int(n["risk_score"] or 0) >= 14
        ]
    );
    has_graph_live: bool = graphState["has_graph"] if graphState else False;
    latest_pr_live: dict | None = graphState["latest_analysis"] if graphState else None;
    latest_verdict_live: dict | None = latest_pr_live["verdict"]
        if latest_pr_live and latest_pr_live["verdict"]
        else None;
    latest_gap_live: dict | None = graphState["latest_gap_analysis"]
        if graphState
        else None;
    latest_incident_live: dict | None = graphState["latest_incident"]
        if graphState
        else None;
    github_issues_live: list = graphState["github_issues"] if graphState else [];
    issue_digest_live: dict | None = graphState["issue_digest"] if graphState else None;
    issues_error_live: str = str_or(graphState["issues_error"], "")
        if graphState
        else "";
    digest_error_live: str = str_or(graphState["digest_error"], "")
        if graphState
        else "";
    gap_suggestions_live: list = latest_gap_live["suggestions"]
        if latest_gap_live
        else [];
    digest_recommended_live: list = issue_digest_live["recommended"]
        if issue_digest_live and issue_digest_live["recommended"]
        else [];
    digest_summary_live: str = str_or(issue_digest_live["summary"], "")
        if issue_digest_live
        else "";
    doc_files_live: list = [
        n
        for n in live_nodes
        if looks_like_doc(str_or(n["path"], ""))
    ];
    test_files_live: list = [
        n
        for n in live_nodes
        if n["is_test"]
    ];
    heuristic_doc_rows: list = [];
    heuristic_test_rows: list = [];
    for row in live_nodes {
        path = str_or(row["path"], "");
        if not path or row["is_test"] or looks_like_doc(path) {
            continue;
        }
        key = path_key(path);
        has_doc_match = False;
        for drow in doc_files_live {
            if key and contains_text(str_or(drow["path"], "").lower(), key) {
                has_doc_match = True;
                break;
            }
        }
        if not has_doc_match and len(heuristic_doc_rows) < 5 {
            heuristic_doc_rows = heuristic_doc_rows
                + [
                    {
                        "path": path,
                        "status": "Docs review suggested",
                        "note": "No matching docs file detected in the current graph snapshot"
                    }
                ];
        }
        has_test_match = False;
        for trow in test_files_live {
            if key and contains_text(str_or(trow["path"], "").lower(), key) {
                has_test_match = True;
                break;
            }
        }
        if (not has_test_match)
            and int(row["risk_score"] or 0) >= 10
            and len(heuristic_test_rows) < 5 {
            heuristic_test_rows = heuristic_test_rows
                + [
                    {
                        "suite": path,
                        "status": "Missing tests",
                        "note": "Risk score "
                            + str(int(row["risk_score"] or 0))
                            + " without a matching test file"
                    }
                ];
        }
    }
    doc_gap_count: int = len(
        [
            row
            for row in gap_suggestions_live
            if str(row["suggestion_type"] or "") == "missing_docs"
        ]
    );
    test_gap_count: int = len(
        [
            row
            for row in gap_suggestions_live
            if str(row["suggestion_type"] or "")
                in ["missing_tests", "incomplete_feature"]
        ]
    );
    if doc_gap_count == 0 {
        doc_gap_count = len(heuristic_doc_rows);
    }
    if test_gap_count == 0 {
        test_gap_count = len(heuristic_test_rows);
    }
    security_findings_count: int = safeLen(latest_verdict_live["security_findings"])
        if latest_verdict_live
        else 0;
    compatibility_findings_count: int = safeLen(
        latest_verdict_live["compatibility_issues"]
    )
        if latest_verdict_live
        else 0;
    latest_threat_count: int = security_findings_count + compatibility_findings_count;
    if latest_threat_count == 0 {
        latest_threat_count = high_risk_count;
    }
    latest_risk_label: str = str_or(latest_verdict_live["overall_risk"], "None yet")
        if latest_verdict_live
        else "None yet";
    graph_edge_count: int = safeLen(live_edges);

    contributor_summary_cards: list = [
        {
            "label": "Files scanned",
            "value": str(len(live_nodes)) if graphState else "—",
            "delta": "current graph",
            "tone": "frost",
            "spark": "6,32 42,22 80,18 122,24 160,12 198,16 236,14 274,10"
        },
        {
            "label": "Links mapped",
            "value": str(graph_edge_count) if graphState else "—",
            "delta": "import edges",
            "tone": "cyan",
            "spark": "6,30 42,28 80,20 122,26 160,16 198,14 236,12 274,11"
        },
        {
            "label": "Threats flagged",
            "value": str(latest_threat_count) if graphState else "—",
            "delta": (
                str(security_findings_count)
                    + " security · "
                    + str(compatibility_findings_count)
                    + " compat"
                    if latest_verdict_live
                    else str(high_risk_count) + " high-risk files"
            ),
            "tone": "aqua",
            "spark": "6,26 42,22 80,24 122,18 160,20 198,11 236,14 274,9"
        },
        {
            "label": "Latest PR risk",
            "value": latest_risk_label,
            "delta": (
                parse_pr_ref(str_or(latest_pr_live["pr_url"], ""))
                    if latest_pr_live
                    else ("graph ready" if has_graph_live else "waiting on graph")
            ),
            "tone": "amber",
            "spark": "6,34 42,24 80,22 122,18 160,20 198,13 236,10 274,12"
        }
    ];

    live_summary_cards: list = [
        {
            "label": "Files scanned",
            "value": str(len(live_nodes)) if graphState else "—",
            "delta": "in graph",
            "tone": "frost",
            "spark": "6,30 42,18 80,20 122,10 160,16 198,8 236,14 274,9"
        },
        {
            "label": "Dependency links",
            "value": str(graph_edge_count) if graphState else "—",
            "delta": "mapped edges",
            "tone": "cyan",
            "spark": "6,34 42,32 80,24 122,28 160,14 198,18 236,12 274,10"
        },
        {
            "label": "Threats flagged",
            "value": str(latest_threat_count) if graphState else "—",
            "delta": (
                str(security_findings_count)
                    + " security · "
                    + str(compatibility_findings_count)
                    + " compat"
                    if latest_verdict_live
                    else str(high_risk_count) + " high-risk files"
            ),
            "tone": "aqua",
            "spark": "6,28 42,20 80,22 122,14 160,18 198,12 236,16 274,11"
        },
        {
            "label": "Latest PR risk",
            "value": latest_risk_label,
            "delta": (
                parse_pr_ref(str_or(latest_pr_live["pr_url"], ""))
                    if latest_pr_live
                    else ("graph ready" if has_graph_live else "waiting on graph")
            ),
            "tone": "amber",
            "spark": "6,36 42,26 80,24 122,20 160,18 198,15 236,11 274,10"
        }
    ];

    summaryCards = contributor_summary_cards if isContributor else live_summary_cards;

    walker_state_str: str = "Running"
        if analysisLoading
        else ("Active" if has_graph_live else "Idle");
    live_walker_status: list = [
        {"name": "SecurityAuditorWalker", "state": walker_state_str},
        {"name": "CompatibilityCheckerWalker", "state": walker_state_str},
        {"name": "BlastRadiusMapperWalker", "state": walker_state_str}
    ];
    contributor_walker_status: list = [
        {"name": "GraphStateWalker", "state": "Active" if graphState else "Idle"},
        {
            "name": "GapAnalysisWalker",
            "state": "Ready" if latest_gap_live else "Waiting"
        },
        {
            "name": "IssueDigest",
            "state": (
                "Loaded"
                    if digest_summary_live
                    else "Needs token"
                        if issues_error_live
                        else "Error" if digest_error_live else "Pending"
            )
        }
    ];
    walkerItems = contributor_walker_status if isContributor else live_walker_status;

    live_attention_items: list = [
        {"title": "Files in graph", "value": f"{len(live_nodes)} nodes"},
        {"title": "High-risk files", "value": f"{high_risk_count} detected"},
        {
            "title": "Latest incident",
            "value": latest_incident_live["status"] if latest_incident_live else "None"
        }
    ];
    contributor_attention_items: list = [
        {
            "title": "Open issues",
            "value": f"{safeLen(github_issues_live)} visible"
                if safeLen(github_issues_live) > 0
                else "Unavailable"
        },
        {
            "title": "Recommended picks",
            "value": f"{safeLen(digest_recommended_live)} ranked"
                if safeLen(digest_recommended_live) > 0
                else "Waiting"
        },
        {
            "title": "Latest gap run",
            "value": str_or(latest_gap_live["created_at"], "Not yet run")
                if latest_gap_live
                else "Not yet run"
        }
    ];
    attentionItems = contributor_attention_items
        if isContributor
        else live_attention_items;

    contributor_issue_rows: list = github_issues_live
        if safeLen(github_issues_live) > 0
        else CONTRIBUTOR_GITHUB_ISSUES;
    contributor_ai_rows: list = [];
    if safeLen(digest_recommended_live) > 0 {
        contributor_ai_rows = [
            {
                "id": "#" + str(row["issue_number"]),
                "title": str_or(row["title"], "Untitled issue"),
                "reason": str_or(row["reason"], "High impact")
            } for row in digest_recommended_live
        ];
    } elif safeLen(gap_suggestions_live) > 0 {
        idx: int = 1;
        for row in gap_suggestions_live {
            contributor_ai_rows = contributor_ai_rows
                + [
                    {
                        "id": "GW-" + str(idx),
                        "title": str_or(row["title"], "Suggested task"),
                        "reason": str_or(row["description"], "Gap surfaced by analysis")
                    }
                ];
            idx = idx + 1;
        }
    } else {
        contributor_ai_rows = CONTRIBUTOR_AI_ISSUES;
    }

    contributor_doc_rows: list = [
        {
            "path": str_or(row["file_path"], ""),
            "status": "Missing docs",
            "note": str_or(row["description"], "")
        }
        for row in gap_suggestions_live
        if str(row["suggestion_type"] or "") == "missing_docs"
    ];
    if len(contributor_doc_rows) == 0 {
        contributor_doc_rows = heuristic_doc_rows
            if len(heuristic_doc_rows) > 0
            else CONTRIBUTOR_DOCS_ROWS;
    }

    contributor_test_rows: list = [
        {
            "suite": str_or(row["file_path"], ""),
            "status": (
                "Incomplete feature"
                    if str(row["suggestion_type"] or "") == "incomplete_feature"
                    else "Missing tests"
            ),
            "note": str_or(row["description"], "")
        }
        for row in gap_suggestions_live
        if str(row["suggestion_type"] or "") in ["missing_tests", "incomplete_feature"]
    ];
    if len(contributor_test_rows) == 0 {
        contributor_test_rows = heuristic_test_rows
            if len(heuristic_test_rows) > 0
            else CONTRIBUTOR_TEST_ROWS;
    }

    contributor_activity_rows: list = [];
    if latest_pr_live {
        contributor_activity_rows = contributor_activity_rows
            + [
                {
                    "when": str_or(latest_pr_live["created_at"], "recent"),
                    "what": "PR analysis completed for "
                        + parse_pr_ref(str_or(latest_pr_live["pr_url"], ""))
                }
            ];
    }
    if latest_gap_live {
        contributor_activity_rows = contributor_activity_rows
            + [
                {
                    "when": str_or(latest_gap_live["created_at"], "recent"),
                    "what": "Gap analysis refreshed with "
                        + str(safeLen(gap_suggestions_live))
                        + " suggestions"
                }
            ];
    }
    if latest_incident_live {
        contributor_activity_rows = contributor_activity_rows
            + [
                {
                    "when": str_or(latest_incident_live["updated_at"], "recent"),
                    "what": "Incident state is "
                        + str_or(latest_incident_live["status"], "unknown")
                }
            ];
    }
    if len(contributor_activity_rows) == 0 {
        contributor_activity_rows = CONTRIBUTOR_ACTIVITY_ROWS;
    }

    contributor_saved_repos: list = [
        {"slug": repoDisplay, "role": "Contributor", "pinned": "true"}
    ]
        if repoDisplay
        else CONTRIBUTOR_SAVED_REPOS;

    maintainer_pr_rows: list = [
        {
            "pr": parse_pr_ref(str_or(latest_pr_live["pr_url"], "")),
            "title": str_or(latest_pr_live["pr_url"], "Latest analyzed pull request"),
            "author": "—",
            "risk": (
                str_or(latest_pr_live["verdict"]["overall_risk"], "unknown")
                    if latest_pr_live and latest_pr_live["verdict"]
                    else "unknown"
            ),
            "status": str_or(latest_pr_live["created_at"], "recent")
        }
    ]
        if latest_pr_live
        else MAINTAINER_PR_REVIEW_ROWS;

    maintainer_dependency_rows: list = [
        {
            "package": str_or(
                latest_incident_live["dependency_name"],
                str_or(latest_incident_live["manifest_path"], "Latest incident")
            ),
            "change": str_or(
                latest_incident_live["dependency_version"],
                str_or(
                    latest_incident_live["commit_sha"], "Observed in current snapshot"
                )
            ),
            "severity": str_or(latest_incident_live["risk_level"], "unknown"),
            "note": str_or(
                latest_incident_live["status"],
                str_or(latest_incident_live["alert_state"], "Needs review")
            )
        }
    ]
        if latest_incident_live
        else MAINTAINER_DEPENDENCY_ROWS;

    maintainer_incident_rows: list = [
        {
            "time": str_or(
                latest_incident_live["updated_at"],
                str_or(latest_incident_live["created_at"], "recent")
            ),
            "severity": str_or(latest_incident_live["risk_level"], "unknown"),
            "title": (
                "Dependency incident: "
                + str_or(latest_incident_live["dependency_name"], "current repo")
            ),
            "detail": (
                "Manifest "
                + str_or(latest_incident_live["manifest_path"], "unknown")
                + " is marked "
                + str_or(latest_incident_live["status"], "open")
            ),
            "hint": (
                str_or(latest_incident_live["fix_pr_url"], "")
                    if str_or(latest_incident_live["fix_pr_url"], "")
                    else str_or(
                        latest_incident_live["next_escalation_at"],
                        "Review incident details"
                    )
            )
        }
    ]
        if latest_incident_live
        else INCIDENTS;

    maintainer_watched_repos: list = [
        {
            "slug": repoDisplay,
            "role": "Lead maintainer",
            "branch": "main",
            "pinned": "true"
        }
    ]
        if repoDisplay
        else MAINTAINER_WATCHED_REPOS;

    def setSection(label: str) -> None {
        activeSection = label;
    }

    panelTitle = repoDisplay;
    topDescription = "";
    searchPlaceholder = "";
    analysisButtonLabel = "Run Analysis";

    if isContributor {
        if activeSection == "Overview" {
            panelTitle = "Overview";
            topDescription = "";
            searchPlaceholder = "Search paths and symbols in " + repoDisplay;
            analysisButtonLabel = "Analyze";
        } else {
            if activeSection == "Suggestions" {
                panelTitle = "Suggestions";
                topDescription = "";
                searchPlaceholder = "Filter issues and suggested tasks";
                analysisButtonLabel = "Analyze";
            } else {
                if activeSection == "Docs & tests" {
                    panelTitle = "Docs & tests";
                    topDescription = "";
                    searchPlaceholder = "Search doc or test paths";
                    analysisButtonLabel = "Analyze";
                } else {
                    if activeSection == "Activity" {
                        panelTitle = "Activity";
                        topDescription = "";
                        searchPlaceholder = "Search recent GhostWatch events";
                        analysisButtonLabel = "Analyze";
                    } else {
                        panelTitle = "Settings";
                        topDescription = "";
                        searchPlaceholder = "Search settings";
                        analysisButtonLabel = "Save changes";
                    }
                }
            }
        }
    } else {
        if activeSection == "Overview" {
            panelTitle = "Overview";
            topDescription = "";
            searchPlaceholder = "Search alerts, walkers, or paths in " + repoDisplay;
            analysisButtonLabel = "Run Analysis";
        } else {
            if activeSection == "PR Review" {
                panelTitle = "PR Review";
                topDescription = "";
                searchPlaceholder = "Search PR titles or authors";
                analysisButtonLabel = "Refresh PR list";
            } else {
                if activeSection == "Dependency Alerts" {
                    panelTitle = "Dependency Alerts";
                    topDescription = "";
                    searchPlaceholder = "Search packages or CVEs";
                    analysisButtonLabel = "Rescan dependencies";
                } else {
                    if activeSection == "Incidents" {
                        panelTitle = "Incidents";
                        topDescription = "";
                        searchPlaceholder = "Search incident titles";
                        analysisButtonLabel = "Refresh incidents";
                    } else {
                        panelTitle = "Settings";
                        topDescription = "";
                        searchPlaceholder = "Search settings";
                        analysisButtonLabel = "Save changes";
                    }
                }
            }
        }
    }

    graphKicker = "Placeholder";
    graphTitle = "Graph Canvas Reserved";
    graphBody = (
        "Live topology playback will attach here in the next build. The shell deliberately keeps this area blank rather than pretending a graph already exists."
    );
    graphFoot = (
        "Reserved for live graph traversal, walker movement, and affected-node emphasis."
    );

    walkerRailTitle = "Walker Status";
    walkerRailCopy = (
        "Distinct specialist states stay visible instead of collapsing into one undifferentiated agent badge."
    );

    attentionTitle = "Attention Needed";
    attentionCopy = (
        "High-signal tasks stay short, legible, and ready for a future live handoff."
    );

    profileStrong = "Lead maintainer";
    profileSpan = "Defense desk preview";

    if isContributor {
        graphKicker = "Contributor map";
        graphTitle = "Contribution graph reserved";
        graphBody = (
            "When live, this panel would tie suggestions to repo topology. The canvas stays blank so we do not fake a graph."
        );
        graphFoot = (
            "Reserved for linking gap suggestions to nodes you touched in recent merges."
        );

        walkerRailTitle = "Walker & gap signals";
        walkerRailCopy = (
            "Gap analysis and doc-linking walkers would surface here instead of the full incident stack."
        );

        attentionTitle = "Your queue";
        attentionCopy = (
            "Contributor-sized tasks distilled from analysis: claimable slices, not org-wide escalations."
        );

        profileStrong = "Contributor view";
        profileSpan = "Gap analysis preview";
    }

    return
        <div className="gw-page">
            <AmbientBackground screen="app"/>
            <div className="gw-page-inner gw-page-inner--app">
                <div className="gw-app-shell">
                    <aside
                        className="gw-sidebar gw-glass-panel gw-fade-up gw-stagger-1"
                    >
                        <Link to="/" className="gw-wordmark-link">
                            <GhostWatchWordmark showSubtitle={False}/>
                        </Link>
                        <div className="gw-sidebar-nav">
                            {[
                                <SidebarNavButton
                                    key={item["label"]}
                                    item={item}
                                    activeSection={activeSection}
                                    onPick={setSection}
                                /> for item in sidebarItems
                            ]}
                        </div>
                        <div className="gw-sidebar-footer">
                            <div className="gw-demo-badge">Demo Mode</div>
                            <Link
                                to="/start"
                                className="gw-role-back"
                                style={{"marginBottom": "12px"}}
                            >
                                Switch role
                            </Link>
                            <div className="gw-profile-card">
                                <div className="gw-avatar">GW</div>
                                <div className="gw-profile-meta">
                                    <strong>{profileStrong}</strong>
                                    <span>{profileSpan}</span>
                                </div>
                            </div>
                        </div>
                    </aside>
                    <div className="gw-workspace">
                        {<header
                            className="gw-topbar gw-glass-panel gw-fade-up gw-stagger-2"
                        >
                            <div className="gw-topbar-heading">
                                <h1>{panelTitle}</h1>
                                {topDescription and <p>{topDescription}</p>}
                            </div>
                            <div className="gw-topbar-actions">
                                <button type="button" className="gw-repo-select">
                                    <svg
                                        width="18"
                                        height="18"
                                        viewBox="0 0 24 24"
                                        fill="none"
                                        aria-hidden="true"
                                    >
                                        <path
                                            d="M12 3L4 7V17L12 21L20 17V7L12 3Z"
                                            stroke="rgba(220,239,255,0.82)"
                                            strokeWidth="1.6"
                                        ></path>
                                        <path
                                            d="M4 7L12 11L20 7"
                                            stroke="rgba(125,211,255,0.82)"
                                            strokeWidth="1.6"
                                        ></path>
                                    </svg>
                                    <span className="gw-repo-label">
                                        <strong>{repoDisplay}</strong>
                                        <span>Active repository</span>
                                    </span>
                                </button>
                                <div className="gw-search-shell">
                                    <svg
                                        width="18"
                                        height="18"
                                        viewBox="0 0 24 24"
                                        fill="none"
                                        aria-hidden="true"
                                    >
                                        <circle
                                            cx="11"
                                            cy="11"
                                            r="6.5"
                                            stroke="rgba(220,239,255,0.58)"
                                            strokeWidth="1.6"
                                        ></circle>
                                        <path
                                            d="M16 16L20 20"
                                            stroke="rgba(220,239,255,0.58)"
                                            strokeWidth="1.6"
                                            strokeLinecap="round"
                                        ></path>
                                    </svg>
                                    <input
                                        className="gw-search-input"
                                        placeholder={searchPlaceholder}
                                    />
                                </div>
                                <button
                                    type="button"
                                    className="gw-glass-button gw-button-primary"
                                    onClick={lambda () -> None { runAnalysis(); }}
                                    disabled={analysisLoading}
                                >
                                    {analysisButtonLabel
                                        if not analysisLoading
                                        else "Analyzing..."}
                                </button>
                            </div>
                        </header>}{isContributor
                            and activeSection == "Suggestions"
                            and <div
                                className="gw-main-grid gw-main-grid--single gw-fade-up gw-stagger-3"
                            >
                                <main className="gw-main-column">
                                    <section className="gw-table-panel gw-glass-panel">
                                        <h2 className="gw-table-panel-title">
                                            Open issues on this repository
                                        </h2>
                                        {issues_error_live
                                            and <p className="gw-settings-hint">
                                                {issues_error_live}
                                            </p>}
                                        <table className="gw-data-table">
                                            <thead>
                                                <tr>
                                                    <th>#</th>
                                                    <th>Title</th>
                                                    <th>Labels</th>
                                                    <th>State</th>
                                                </tr>
                                            </thead>
                                            <tbody>
                                                {[
                                                    <tr key={row["id"]}>
                                                        <td>{row["id"]}</td>
                                                        <td>{row["title"]}</td>
                                                        <td>{row["labels"]}</td>
                                                        <td>{row["state"]}</td>
                                                    </tr>
                                                    for row in contributor_issue_rows
                                                ]}
                                            </tbody>
                                        </table>
                                    </section>
                                    <section className="gw-table-panel gw-glass-panel">
                                        <h2 className="gw-table-panel-title">
                                            Recommended by AI
                                        </h2>
                                        {(digest_summary_live or digest_error_live)
                                            and <p className="gw-settings-hint">
                                                {digest_summary_live
                                                    if digest_summary_live
                                                    else digest_error_live}
                                            </p>}
                                        <table className="gw-data-table">
                                            <thead>
                                                <tr>
                                                    <th>ID</th>
                                                    <th>Suggested task</th>
                                                    <th>Why it matters</th>
                                                </tr>
                                            </thead>
                                            <tbody>
                                                {[
                                                    <tr key={row["id"]}>
                                                        <td>{row["id"]}</td>
                                                        <td>{row["title"]}</td>
                                                        <td>{row["reason"]}</td>
                                                    </tr> for row in contributor_ai_rows
                                                ]}
                                            </tbody>
                                        </table>
                                    </section>
                                </main>
                            </div>}{isContributor
                            and activeSection == "Docs & tests"
                            and <div
                                className="gw-main-grid gw-main-grid--single gw-fade-up gw-stagger-3"
                            >
                                <main className="gw-main-column">
                                    <section className="gw-table-panel gw-glass-panel">
                                        <h2 className="gw-table-panel-title">
                                            Documentation
                                        </h2>
                                        <table className="gw-data-table">
                                            <thead>
                                                <tr>
                                                    <th>Path</th>
                                                    <th>Status</th>
                                                    <th>Note</th>
                                                </tr>
                                            </thead>
                                            <tbody>
                                                {[
                                                    <tr key={row["path"]}>
                                                        <td>{row["path"]}</td>
                                                        <td>{row["status"]}</td>
                                                        <td>{row["note"]}</td>
                                                    </tr>
                                                    for row in contributor_doc_rows
                                                ]}
                                            </tbody>
                                        </table>
                                    </section>
                                    <section className="gw-table-panel gw-glass-panel">
                                        <h2 className="gw-table-panel-title">Tests</h2>
                                        <table className="gw-data-table">
                                            <thead>
                                                <tr>
                                                    <th>Suite / area</th>
                                                    <th>Status</th>
                                                    <th>Note</th>
                                                </tr>
                                            </thead>
                                            <tbody>
                                                {[
                                                    <tr key={row["suite"]}>
                                                        <td>{row["suite"]}</td>
                                                        <td>{row["status"]}</td>
                                                        <td>{row["note"]}</td>
                                                    </tr>
                                                    for row in contributor_test_rows
                                                ]}
                                            </tbody>
                                        </table>
                                    </section>
                                </main>
                            </div>}{isContributor
                            and activeSection == "Activity"
                            and <div
                                className="gw-main-grid gw-main-grid--single gw-fade-up gw-stagger-3"
                            >
                                <main className="gw-main-column">
                                    <section className="gw-table-panel gw-glass-panel">
                                        <h2 className="gw-table-panel-title">
                                            Recent activity
                                        </h2>
                                        <table
                                            className="gw-data-table gw-data-table--compact"
                                        >
                                            <thead>
                                                <tr>
                                                    <th>When</th>
                                                    <th>Event</th>
                                                </tr>
                                            </thead>
                                            <tbody>
                                                {[
                                                    <tr key={row["when"] + row["what"]}>
                                                        <td>{row["when"]}</td>
                                                        <td>{row["what"]}</td>
                                                    </tr>
                                                    for row in contributor_activity_rows
                                                ]}
                                            </tbody>
                                        </table>
                                    </section>
                                </main>
                            </div>}{isContributor
                            and activeSection == "Settings"
                            and <div
                                className="gw-main-grid gw-main-grid--single gw-fade-up gw-stagger-3"
                            >
                                <main className="gw-main-column gw-settings-column">
                                    <section
                                        className="gw-settings-block gw-glass-panel"
                                    >
                                        <h2 className="gw-table-panel-title">
                                            Notifications
                                        </h2>
                                        <label className="gw-settings-row">
                                            <input
                                                type="checkbox"
                                                defaultChecked={True}
                                            />
                                            <span>
                                                Email when a new AI suggestion batch is ready
                                            </span>
                                        </label>
                                        <label className="gw-settings-row">
                                            <input
                                                type="checkbox"
                                                defaultChecked={True}
                                            />
                                            <span>
                                                Slack digest for assigned issues
                                            </span>
                                        </label>
                                        <label className="gw-settings-row">
                                            <input
                                                type="checkbox"
                                                defaultChecked={False}
                                            />
                                            <span>
                                                Desktop alerts for failing checks on watched repos
                                            </span>
                                        </label>
                                    </section>
                                    <section
                                        className="gw-settings-block gw-glass-panel"
                                    >
                                        <h2 className="gw-table-panel-title">
                                            Analysis
                                        </h2>
                                        <label className="gw-settings-row">
                                            <span className="gw-settings-label">
                                                Default gap run depth
                                            </span>
                                            <select
                                                className="gw-settings-select"
                                                defaultValue="standard"
                                            >
                                                <option value="shallow">Shallow</option>
                                                <option value="standard">
                                                    Standard
                                                </option>
                                                <option value="deep">
                                                    Deep (slower)
                                                </option>
                                            </select>
                                        </label>
                                        <label className="gw-settings-row">
                                            <span className="gw-settings-label">
                                                Time zone for digests
                                            </span>
                                            <select
                                                className="gw-settings-select"
                                                defaultValue="utc"
                                            >
                                                <option value="utc">UTC</option>
                                                <option value="local">
                                                    Local browser
                                                </option>
                                            </select>
                                        </label>
                                    </section>
                                    <section className="gw-table-panel gw-glass-panel">
                                        <h2 className="gw-table-panel-title">
                                            Repositories you contribute to
                                        </h2>
                                        <table className="gw-data-table">
                                            <thead>
                                                <tr>
                                                    <th>Repository</th>
                                                    <th>Role</th>
                                                    <th>Pinned in sidebar</th>
                                                </tr>
                                            </thead>
                                            <tbody>
                                                {[
                                                    <tr
                                                        key={row["slug"]}
                                                        className={(
                                                            "gw-repo-row-current"
                                                                if row["slug"]
                                                                    == repoDisplay
                                                                else ""
                                                        )}
                                                    >
                                                        <td>{row["slug"]}</td>
                                                        <td>{row["role"]}</td>
                                                        <td>
                                                            {(
                                                                "Yes"
                                                                    if row["pinned"]
                                                                        == "true"
                                                                    else "No"
                                                            )}
                                                        </td>
                                                    </tr>
                                                    for row in contributor_saved_repos
                                                ]}
                                            </tbody>
                                        </table>
                                        <p className="gw-settings-hint">
                                            The repo you linked ({repoDisplay}) is highlighted when it matches a row above.
                                        </p>
                                    </section>
                                </main>
                            </div>}{(not isContributor)
                            and activeSection == "PR Review"
                            and <div
                                className="gw-main-grid gw-main-grid--single gw-fade-up gw-stagger-3"
                            >
                                <main className="gw-main-column">
                                    <section className="gw-table-panel gw-glass-panel">
                                        <h2 className="gw-table-panel-title">
                                            Pull requests under watch
                                        </h2>
                                        <table className="gw-data-table">
                                            <thead>
                                                <tr>
                                                    <th>PR</th>
                                                    <th>Title</th>
                                                    <th>Author</th>
                                                    <th>Risk</th>
                                                    <th>Status</th>
                                                </tr>
                                            </thead>
                                            <tbody>
                                                {[
                                                    <tr key={row["pr"]}>
                                                        <td>{row["pr"]}</td>
                                                        <td>{row["title"]}</td>
                                                        <td>{row["author"]}</td>
                                                        <td>{row["risk"]}</td>
                                                        <td>{row["status"]}</td>
                                                    </tr> for row in maintainer_pr_rows
                                                ]}
                                            </tbody>
                                        </table>
                                    </section>
                                </main>
                            </div>}{(not isContributor)
                            and activeSection == "Dependency Alerts"
                            and <div
                                className="gw-main-grid gw-main-grid--single gw-fade-up gw-stagger-3"
                            >
                                <main className="gw-main-column">
                                    <section className="gw-table-panel gw-glass-panel">
                                        <h2 className="gw-table-panel-title">
                                            Dependency & manifest signals
                                        </h2>
                                        <table className="gw-data-table">
                                            <thead>
                                                <tr>
                                                    <th>Package / source</th>
                                                    <th>Change</th>
                                                    <th>Severity</th>
                                                    <th>Note</th>
                                                </tr>
                                            </thead>
                                            <tbody>
                                                {[
                                                    <tr key={row["package"]}>
                                                        <td>{row["package"]}</td>
                                                        <td>{row["change"]}</td>
                                                        <td>{row["severity"]}</td>
                                                        <td>{row["note"]}</td>
                                                    </tr>
                                                    for row in maintainer_dependency_rows
                                                ]}
                                            </tbody>
                                        </table>
                                    </section>
                                </main>
                            </div>}{(not isContributor)
                            and activeSection == "Incidents"
                            and <div
                                className="gw-main-grid gw-main-grid--single gw-fade-up gw-stagger-3"
                            >
                                <main className="gw-main-column">
                                    <section className="gw-table-panel gw-glass-panel">
                                        <h2 className="gw-table-panel-title">
                                            Escalation feed
                                        </h2>
                                        <table className="gw-data-table">
                                            <thead>
                                                <tr>
                                                    <th>Time</th>
                                                    <th>Severity</th>
                                                    <th>Title</th>
                                                    <th>Detail</th>
                                                    <th>Next step</th>
                                                </tr>
                                            </thead>
                                            <tbody>
                                                {[
                                                    <tr key={incident["title"]}>
                                                        <td>{incident["time"]}</td>
                                                        <td>{incident["severity"]}</td>
                                                        <td>{incident["title"]}</td>
                                                        <td>{incident["detail"]}</td>
                                                        <td>{incident["hint"]}</td>
                                                    </tr>
                                                    for incident in maintainer_incident_rows
                                                ]}
                                            </tbody>
                                        </table>
                                    </section>
                                </main>
                            </div>}{(not isContributor)
                            and activeSection == "Settings"
                            and <div
                                className="gw-main-grid gw-main-grid--single gw-fade-up gw-stagger-3"
                            >
                                <main className="gw-main-column gw-settings-column">
                                    <section
                                        className="gw-settings-block gw-glass-panel"
                                    >
                                        <h2 className="gw-table-panel-title">
                                            Notifications
                                        </h2>
                                        <label className="gw-settings-row">
                                            <input
                                                type="checkbox"
                                                defaultChecked={True}
                                            />
                                            <span>
                                                Page me when a critical incident opens on a watched repo
                                            </span>
                                        </label>
                                        <label className="gw-settings-row">
                                            <input
                                                type="checkbox"
                                                defaultChecked={True}
                                            />
                                            <span>
                                                Slack #defense-desk for high+ dependency alerts
                                            </span>
                                        </label>
                                        <label className="gw-settings-row">
                                            <input
                                                type="checkbox"
                                                defaultChecked={False}
                                            />
                                            <span>
                                                Email digest of PRs blocked on maintainer approval
                                            </span>
                                        </label>
                                    </section>
                                    <section
                                        className="gw-settings-block gw-glass-panel"
                                    >
                                        <h2 className="gw-table-panel-title">
                                            Walker desk
                                        </h2>
                                        <label className="gw-settings-row">
                                            <span className="gw-settings-label">
                                                Default blast-radius depth
                                            </span>
                                            <select
                                                className="gw-settings-select"
                                                defaultValue="standard"
                                            >
                                                <option value="shallow">Shallow</option>
                                                <option value="standard">
                                                    Standard
                                                </option>
                                                <option value="deep">
                                                    Deep (slower)
                                                </option>
                                            </select>
                                        </label>
                                        <label className="gw-settings-row">
                                            <span className="gw-settings-label">
                                                Auto-escalate policy
                                            </span>
                                            <select
                                                className="gw-settings-select"
                                                defaultValue="manual"
                                            >
                                                <option value="manual">
                                                    Manual approval only
                                                </option>
                                                <option value="trusted">
                                                    Auto for trusted authors
                                                </option>
                                            </select>
                                        </label>
                                    </section>
                                    <section className="gw-table-panel gw-glass-panel">
                                        <h2 className="gw-table-panel-title">
                                            Watched repositories
                                        </h2>
                                        <table className="gw-data-table">
                                            <thead>
                                                <tr>
                                                    <th>Repository</th>
                                                    <th>Role</th>
                                                    <th>Default branch</th>
                                                    <th>Pinned</th>
                                                </tr>
                                            </thead>
                                            <tbody>
                                                {[
                                                    <tr
                                                        key={row["slug"]}
                                                        className={(
                                                            "gw-repo-row-current"
                                                                if row["slug"]
                                                                    == repoDisplay
                                                                else ""
                                                        )}
                                                    >
                                                        <td>{row["slug"]}</td>
                                                        <td>{row["role"]}</td>
                                                        <td>{row["branch"]}</td>
                                                        <td>
                                                            {(
                                                                "Yes"
                                                                    if row["pinned"]
                                                                        == "true"
                                                                    else "No"
                                                            )}
                                                        </td>
                                                    </tr>
                                                    for row in maintainer_watched_repos
                                                ]}
                                            </tbody>
                                        </table>
                                        <p className="gw-settings-hint">
                                            The linked repo ({repoDisplay}) is highlighted when it matches a row above.
                                        </p>
                                    </section>
                                </main>
                            </div>}{isContributor
                            and activeSection == "Overview"
                            and <div className="gw-main-grid gw-fade-up gw-stagger-3">
                                <main className="gw-main-column">
                                    <section className="gw-summary-grid">
                                        {[
                                            <SummaryCard
                                                key={card["label"]}
                                                card={card}
                                            /> for card in summaryCards
                                        ]}
                                    </section>
                                    <section
                                        className="gw-graph-panel gw-glass-panel gw-fade-up gw-stagger-5"
                                    >
                                        {(graphState and len(graphState["nodes"]) > 0)
                                            and <GraphView
                                                nodes_data={graphState["nodes"]}
                                                edges_data={graphState["edges"]}
                                                animatingPath={animatingPath}
                                                analysisLoading={analysisLoading}
                                                scanResult={analysisResult is not None
                                                    and not analysisLoading}
                                            />}{(
                                            not graphState
                                            or len(graphState["nodes"]) == 0
                                        )
                                            and <div>
                                                <div
                                                    className="gw-graph-inner-frame"
                                                ></div>
                                                <GraphPlaceholderAccent/>
                                                <div className="gw-graph-copy">
                                                    <span>{graphKicker}</span>
                                                    <h2>{graphTitle}</h2>
                                                    <p>{graphBody}</p>
                                                    {graphFetchError
                                                        and <p
                                                            style={{
                                                                "color": "rgba(239,68,68,0.8)",
                                                                "fontSize": "11px",
                                                                "fontFamily": "monospace"
                                                            }}
                                                        >
                                                            {"fetch error: "
                                                                + graphFetchError}
                                                        </p>}
                                                    <div className="gw-graph-foot">
                                                        {graphFoot}
                                                    </div>
                                                </div>
                                            </div>}
                                    </section>
                                </main>
                                <aside className="gw-right-rail">
                                    <section
                                        className="gw-right-panel gw-glass-panel gw-fade-up gw-stagger-3"
                                    >
                                        <h3>{walkerRailTitle}</h3>
                                        <p>{walkerRailCopy}</p>
                                        <div className="gw-right-list">
                                            {[
                                                <WalkerStatusItem
                                                    key={status_item["name"]}
                                                    status_item={status_item}
                                                /> for status_item in walkerItems
                                            ]}
                                        </div>
                                    </section>
                                    <section
                                        className="gw-right-panel gw-glass-panel gw-fade-up gw-stagger-4"
                                    >
                                        <h3>{attentionTitle}</h3>
                                        <p>{attentionCopy}</p>
                                        <div className="gw-right-list">
                                            {[
                                                <AttentionItem
                                                    key={item["title"]}
                                                    item={item}
                                                /> for item in attentionItems
                                            ]}
                                        </div>
                                    </section>
                                </aside>
                            </div>}{(not isContributor)
                            and activeSection == "Overview"
                            and <div className="gw-main-grid gw-fade-up gw-stagger-3">
                                <main className="gw-main-column">
                                    <section className="gw-summary-grid">
                                        {[
                                            <SummaryCard
                                                key={card["label"]}
                                                card={card}
                                            /> for card in summaryCards
                                        ]}
                                    </section>
                                    {analysisResult
                                        and <section
                                            className="gw-glass-panel gw-fade-up"
                                            style={{
                                                "padding": "20px 24px",
                                                "marginBottom": "16px",
                                                "borderLeft": "3px solid "
                                                    + (
                                                        "rgba(239,68,68,0.8)"
                                                            if (
                                                                analysisResult[
                                                                    "overall_risk"
                                                                ]
                                                                or ""
                                                            )
                                                                in ["critical", "high"]
                                                            else "rgba(251,191,36,0.8)"
                                                                if (
                                                                    analysisResult[
                                                                        "overall_risk"
                                                                    ]
                                                                    or ""
                                                                )
                                                                    == "medium"
                                                                else "rgba(125,211,255,0.6)"
                                                    )
                                            }}
                                        >
                                            <div
                                                style={{
                                                    "display": "flex",
                                                    "alignItems": "center",
                                                    "gap": "12px",
                                                    "marginBottom": "10px"
                                                }}
                                            >
                                                <span
                                                    style={{
                                                        "background": (
                                                            "rgba(239,68,68,0.25)"
                                                                if (
                                                                    analysisResult[
                                                                        "overall_risk"
                                                                    ]
                                                                    or ""
                                                                )
                                                                    in [
                                                                        "critical",
                                                                        "high"
                                                                    ]
                                                                else "rgba(251,191,36,0.25)"
                                                                    if (
                                                                        analysisResult[
                                                                            "overall_risk"
                                                                        ]
                                                                        or ""
                                                                    )
                                                                        == "medium"
                                                                    else "rgba(125,211,255,0.15)"
                                                        ),
                                                        "color": "rgba(220,239,255,0.9)",
                                                        "padding": "3px 10px",
                                                        "borderRadius": "20px",
                                                        "fontSize": "11px",
                                                        "fontWeight": "700",
                                                        "textTransform": "uppercase",
                                                        "letterSpacing": "0.05em"
                                                    }}
                                                >
                                                    {analysisResult["overall_risk"]
                                                        or "unknown"}
                                                </span>
                                                <span
                                                    style={{
                                                        "color": "rgba(220,239,255,0.5)",
                                                        "fontSize": "12px"
                                                    }}
                                                >
                                                    {str(
                                                        safeLen(
                                                            analysisResult[
                                                                "security_findings"
                                                            ]
                                                        )
                                                    )
                                                        + " security findings · "
                                                        + str(
                                                            safeLen(
                                                                analysisResult[
                                                                    "compatibility_issues"
                                                                ]
                                                            )
                                                        )
                                                        + " compatibility issues"}
                                                </span>
                                            </div>
                                            <p
                                                style={{
                                                    "color": "rgba(220,239,255,0.82)",
                                                    "fontSize": "13px",
                                                    "marginBottom": "6px",
                                                    "lineHeight": "1.5"
                                                }}
                                            >
                                                {analysisResult["blast_radius_summary"]
                                                    or ""}
                                            </p>
                                            <p
                                                style={{
                                                    "color": "rgba(125,211,255,0.82)",
                                                    "fontSize": "12px",
                                                    "fontStyle": "italic"
                                                }}
                                            >
                                                {analysisResult["recommendation"] or ""}
                                            </p>
                                        </section>}
                                    <section
                                        className="gw-graph-panel gw-glass-panel gw-fade-up gw-stagger-5"
                                    >
                                        {(graphState and len(graphState["nodes"]) > 0)
                                            and <GraphView
                                                nodes_data={graphState["nodes"]}
                                                edges_data={graphState["edges"]}
                                                animatingPath={animatingPath}
                                                analysisLoading={analysisLoading}
                                                scanResult={analysisResult is not None
                                                    and not analysisLoading}
                                            />}{(
                                            not graphState
                                            or len(graphState["nodes"]) == 0
                                        )
                                            and <div>
                                                <GraphPlaceholderAccent/>
                                                <div className="gw-graph-copy">
                                                    <span>{graphKicker}</span>
                                                    <h2>{graphTitle}</h2>
                                                    <p>{graphBody}</p>
                                                    {graphFetchError
                                                        and <p
                                                            style={{
                                                                "color": "rgba(239,68,68,0.8)",
                                                                "fontSize": "11px",
                                                                "fontFamily": "monospace"
                                                            }}
                                                        >
                                                            {"fetch error: "
                                                                + graphFetchError}
                                                        </p>}
                                                    <div className="gw-graph-foot">
                                                        {graphFoot}
                                                    </div>
                                                </div>
                                            </div>}
                                    </section>
                                </main>
                                <aside className="gw-right-rail">
                                    <section
                                        className="gw-right-panel gw-glass-panel gw-fade-up gw-stagger-3"
                                    >
                                        <h3>{walkerRailTitle}</h3>
                                        <p>{walkerRailCopy}</p>
                                        <div className="gw-right-list">
                                            {[
                                                <WalkerStatusItem
                                                    key={status_item["name"]}
                                                    status_item={status_item}
                                                /> for status_item in walkerItems
                                            ]}
                                        </div>
                                    </section>
                                    <section
                                        className="gw-right-panel gw-glass-panel gw-fade-up gw-stagger-4"
                                    >
                                        <h3>{attentionTitle}</h3>
                                        <p>{attentionCopy}</p>
                                        <div className="gw-right-list">
                                            {[
                                                <AttentionItem
                                                    key={item["title"]}
                                                    item={item}
                                                /> for item in attentionItems
                                            ]}
                                        </div>
                                    </section>
                                </aside>
                            </div>}
                    </div>
                </div>
            </div>
        </div>;
}
