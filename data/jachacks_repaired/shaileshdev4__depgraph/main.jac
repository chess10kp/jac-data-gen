"""DepGraph — JacHacks 2026 entry point."""

import from walkers.dep_graph_agent { DepGraphAgent }
import from tools.investigation_runner {
    begin_async_investigation,
    poll_status
}

walker:pub start_investigation {
    has repo_url: str;
    has ecosystem: str = "npm";
    has max_direct_deps: int = 8;
    has session_id: str = "";
    has reports: list[dict] = [];

    can run with Root entry {
        result = DepGraphAgent(
            repo_url=self.repo_url,
            ecosystem=self.ecosystem,
            max_direct_deps=self.max_direct_deps,
            session_id=self.session_id
        ) spawn root;
        for ent in result.reports {
            report ent;
        }
    }
}

walker:pub start_investigation_async {
    has repo_url: str;
    has ecosystem: str = "npm";
    has max_direct_deps: int = 8;
    has reports: list[dict] = [];

    can run with Root entry {
        sid = begin_async_investigation(
            self.repo_url,
            self.ecosystem,
            self.max_direct_deps
        );
        report {
            "event": "session_created",
            "session_id": sid,
            "repo_url": self.repo_url,
            "status": "running"
        };
    }
}

walker:pub investigation_status {
    has session_id: str;
    has since: int = 0;
    has reports: list[dict] = [];

    can run with Root entry {
        snap = poll_status(self.session_id, self.since);
        report snap;
    }
}

def:pub app -> JsxElement {
    has repo_url: str = "https://github.com/shaileshdev4/drygate";
    has status: str = "idle";
    has log_text: str = "";
    has findings_text: str = "";
    has error: str = "";

    async def run_investigation() -> None {
        if not repo_url.strip() {
            error = "Enter a GitHub repository URL";
            return;
        }
        status = "running";
        error = "";
        log_text = "Investigating…";
        findings_text = "";
        try {
            result = root spawn start_investigation(
                repo_url=repo_url.strip(),
                ecosystem="npm",
                max_direct_deps=8
            );
            report_rows: list = [];
            if result and result.reports {
                report_rows = result.reports;
            }
            if not report_rows {
                log_text = "No events returned from server.";
                status = "done";
                return;
            }
            lines = "";
            for row in report_rows {
                ev = "unknown";
                if "event" in row {
                    ev = str(row["event"]);
                }
                line = f"- {ev}";
                    if ev == "nvd_result" {
                        pkg = str(row["package"]) if "package" in row else "?";
                        cnt = row["cve_count"] if "cve_count" in row else 0;
                        cvss = row["max_cvss"] if "max_cvss" in row else 0.0;
                        src = str(row["source"]) if "source" in row else "osv";
                        line = f"- {ev}: {pkg} ({cnt} CVEs, max CVSS {cvss}, {src})";
                    }
                    if ev == "route_decision" {
                        pkg = str(row["package"]) if "package" in row else "?";
                        nbr = row["neighbor_count"] if "neighbor_count" in row else 0;
                        line = f"- {ev}: from {pkg} → LLM picks 1 of {nbr} deps";
                    }
                    if ev == "route_chosen" {
                        frm = str(row["from_package"]) if "from_package" in row else "?";
                        mode = str(row["mode"]) if "mode" in row else "?";
                        targets = str(row["targets"]) if "targets" in row else "?";
                        idxs = row["indexes"] if "indexes" in row else [];
                        line = (
                            f"- {ev}: {mode} → {targets} "
                            f"(from {frm}, idx {idxs})"
                        );
                    }
                    if ev == "manifest_parsing" {
                        fname = (
                            str(row["filename"])
                            if "filename" in row
                            else "manifest"
                        );
                        nbytes = row["bytes"] if "bytes" in row else 0;
                        line = f"- {ev}: {fname} ({nbytes} bytes)";
                    }
                    if ev == "manifest_parsed" {
                        cnt = (
                            row["package_count"]
                            if "package_count" in row
                            else 0
                        );
                        trunc = (
                            row["truncated"] if "truncated" in row else False
                        );
                        orig = (
                            row["original_package_count"]
                            if "original_package_count" in row
                            else cnt
                        );
                        method = (
                            str(row["filter_method"])
                            if "filter_method" in row
                            else ""
                        );
                        if trunc {
                            line = (
                                f"- {ev}: {cnt} packages in graph "
                                f"(risk filter from {orig}, {method})"
                            );
                        } else {
                            line = f"- {ev}: {cnt} packages";
                        }
                    }
                    if ev == "lockfile_fetched" {
                        fname = (
                            str(row["filename"])
                            if "filename" in row
                            else "manifest"
                        );
                        kind = (
                            str(row["manifest_kind"])
                            if "manifest_kind" in row
                            else "lockfile"
                        );
                        line = f"- {ev}: {fname} ({kind})";
                    }
                    if ev == "spawn_decision" {
                        cnt = (
                            row["candidate_count"]
                            if "candidate_count" in row
                            else 0
                        );
                        pool = (
                            row["llm_pool_count"]
                            if "llm_pool_count" in row
                            else cnt
                        );
                        line = (
                            f"- {ev}: LLM picks from top {pool} "
                            f"of {cnt} candidates"
                        );
                    }
                    if ev == "spawn_chosen" {
                        mode = str(row["mode"]) if "mode" in row else "?";
                        targets = str(row["targets"]) if "targets" in row else "?";
                        llm_n = row["llm_picks"] if "llm_picks" in row else 0;
                        risk_n = row["risk_picks"] if "risk_picks" in row else 0;
                        if risk_n > 0 {
                            line = (
                                f"- {ev}: {mode} ({llm_n} LLM + "
                                f"{risk_n} risk) → {targets}"
                            );
                        } else {
                            line = f"- {ev}: {mode} → {targets}";
                        }
                    }
                    if ev == "spawn_llm_partial" {
                        llm_n = row["llm_picks"] if "llm_picks" in row else 0;
                        risk_n = row["risk_picks"] if "risk_picks" in row else 0;
                        line = (
                            f"- {ev}: {llm_n} LLM picks, "
                            f"{risk_n} risk fallback (empty model response)"
                        );
                    }
                    if ev == "spawn_llm_failed" {
                        reason = str(row["reason"]) if "reason" in row else "?";
                        line = f"- {ev}: {reason}";
                    }
                    if ev == "deep_dive" {
                        pkg = str(row["package"]) if "package" in row else "?";
                        cve = str(row["cve_id"]) if "cve_id" in row else "?";
                        line = f"- {ev}: {pkg} critical ({cve})";
                    }
                    if ev == "report_generated" {
                        summary = (
                            str(row["summary"])
                            if "summary" in row
                            else ""
                        );
                        line = f"- {ev}: {summary[0:120]}";
                    }
                    if ev == "subtrees_spawned" {
                        cnt = row["spawn_count"] if "spawn_count" in row else 0;
                        mode = str(row["spawn_mode"]) if "spawn_mode" in row else "";
                        line = f"- {ev}: {cnt} subtrees ({mode})";
                    }
                if ev == "investigation_complete" {
                    vuln = (
                        row["vulnerable_count"]
                        if "vulnerable_count" in row
                        else 0
                    );
                    scanned = (
                        row["packages_scanned"]
                        if "packages_scanned" in row
                        else 0
                    );
                    spawns = (
                        row["subtrees_spawned"]
                        if "subtrees_spawned" in row
                        else 0
                    );
                    line = (
                        f"- {ev}: {vuln} vulnerable, "
                        f"{scanned} OSV lookups ({spawns} subtrees)"
                    );
                    items = (
                        row["findings"]
                        if ("findings" in row and row["findings"])
                        else []
                    );
                    if not items {
                        findings_text = (
                            "No CVE matches in scanned direct dependencies."
                        );
                    } else {
                        f_lines = "";
                        for item in items {
                            pkg = str(item["package"]);
                            ver = str(item["version"]);
                            cnt = item["cve_count"];
                            cvss = item["max_cvss"];
                            top = str(item["top_cve"]);
                            f_lines = (
                                f"{f_lines}{pkg}@{ver} — {cnt} CVE(s), "
                                f"max CVSS {cvss} ({top})\n"
                            );
                        }
                        findings_text = f_lines;
                    }
                }
                lines = f"{lines}{line}\n";
            }
            log_text = lines;
            status = "done";
        } except Exception as e {
            error = f"Investigation failed: {e}";
            log_text = "";
            status = "error";
        }
    }

    return
        <div
            style={{
                "minHeight": "100vh",
                "background": "#0b0f14",
                "color": "#e6edf3",
                "padding": "2.5rem",
                "fontFamily": "system-ui, sans-serif",
                "maxWidth": "48rem"
            }}
        >
            <h1 style={{"margin": 0, "fontSize": "2rem"}}>DepGraph</h1>
            <p style={{"color": "#8b949e", "marginTop": "0.5rem"}}>
                Autonomous dependency vulnerability investigation
            </p>
            <input
                type="text"
                placeholder="https://github.com/owner/repo"
                value={repo_url}
                onChange={lambda (e: ChangeEvent) { repo_url = str(e.target.value); }}
                style={{
                    "width": "100%",
                    "marginTop": "1.5rem",
                    "padding": "0.75rem 1rem",
                    "borderRadius": "8px",
                    "border": "1px solid #30363d",
                    "background": "#161b22",
                    "color": "#e6edf3"
                }}
            />
            <button
                onClick={run_investigation}
                disabled={status == "running"}
                style={{
                    "marginTop": "1rem",
                    "padding": "0.65rem 1rem",
                    "borderRadius": "8px",
                    "border": "none",
                    "background": "#238636",
                    "color": "#fff",
                    "cursor": "pointer"
                }}
            >
                Investigate
            </button>
            <p style={{"color": "#f85149", "marginTop": "1rem"}}>
                {error}
            </p>
            <h2 style={{"marginTop": "2rem", "fontSize": "1.1rem"}}>Activity log</h2>
            <pre
                style={{
                    "marginTop": "0.5rem",
                    "padding": "1rem",
                    "background": "#161b22",
                    "border": "1px solid #30363d",
                    "borderRadius": "8px",
                    "fontSize": "0.8rem",
                    "whiteSpace": "pre-wrap"
                }}
            >
                {log_text}
            </pre>
            <h2 style={{"marginTop": "1.5rem", "fontSize": "1.1rem"}}>Vulnerable packages</h2>
            <pre
                style={{
                    "marginTop": "0.5rem",
                    "padding": "1rem",
                    "background": "#161b22",
                    "border": "1px solid #30363d",
                    "borderRadius": "8px",
                    "fontSize": "0.8rem",
                    "whiteSpace": "pre-wrap",
                    "color": "#f0883e"
                }}
            >
                {findings_text}
            </pre>
        </div>;
}
