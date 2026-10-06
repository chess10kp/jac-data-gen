# walkers/static/impl/graph_state.impl.jac
# GraphStateWalker implementation bodies.
# Auto-discovered by jac from walkers/static/graph_state.jac via impl/ convention.

import from graph.nodes {
    FileNode,
    PRAnalysisNode,
    GhostwatchIncidentNode,
    GapAnalysisNode,
    IssueIntelligenceNode
}
import from lib.repo_demo_env { ghostwatch_demo_repo_url, ghostwatch_demo_repo_slug }
import from lib.issue_intel {
    issues_fingerprint_from_list,
    issue_digest_cache_fresh,
    issues_fetch_cache_fresh
}
import from integrations.github { list_open_issues }
import from os { environ }
import from time { time }

impl GraphStateWalker.fetch {
    self.has_graph = len([-->][?:FileNode]) > 0;
    visit [-->];
}

impl GraphStateWalker.collect_file {
    self.nodes_data = self.nodes_data + [
        {
            "id": jid(here),
            "path": here.path,
            "language": here.language,
            "risk_score": here.risk_score,
            "is_test": here.is_test
        }
    ];
    for target in [-->][?:FileNode] {
        self.edges_data = self.edges_data + [
            {"source": jid(here), "target": jid(target)}
        ];
    }
}

impl GraphStateWalker.collect_pr {
    self.latest_pr = {
        "id": jid(here),
        "pr_url": here.pr_url,
        "verdict": here.verdict,
        "created_at": here.created_at
    };
}

impl GraphStateWalker.collect_incident with GhostwatchIncidentNode entry {
    cand = {
        "id": str(jid(here)),
        "dedupe_key": here.dedupe_key,
        "repo_full_name": here.repo_full_name,
        "commit_sha": here.commit_sha,
        "status": here.status,
        "risk_level": here.risk_level,
        "dependency_name": here.dependency_name,
        "dependency_version": here.dependency_version,
        "manifest_path": here.manifest_path,
        "rule_codes": here.rule_codes,
        "fix_pr_url": here.fix_pr_url,
        "sandbox_result": here.sandbox_result,
        "behavioral_trace": here.behavioral_trace,
        "next_escalation_at": here.next_escalation_at,
        "alert_state": here.alert_state,
        "created_at": here.created_at,
        "updated_at": here.updated_at
    };
    if not self.latest_incident {
        self.latest_incident = cand;
    } else {
        if str(cand.get("updated_at", "")) > str(self.latest_incident.get("updated_at", "")) {
            self.latest_incident = cand;
        }
    }
}

impl GraphStateWalker.collect_gap with GapAnalysisNode entry {
    cand = {
        "id": str(jid(here)),
        "merge_commit_sha": here.merge_commit_sha,
        "suggestions": here.suggestions,
        "created_at": here.created_at
    };
    if not self.latest_gap {
        self.latest_gap = cand;
    } else {
        if str(cand.get("created_at", "")) > str(self.latest_gap.get("created_at", "")) {
            self.latest_gap = cand;
        }
    }
}

impl GraphStateWalker.finish {
    _demo_u = ghostwatch_demo_repo_url();
    slug = ghostwatch_demo_repo_slug(_demo_u);
    now_ts = int(time());
    token = str(environ.get("GITHUB_TOKEN", "")).strip();
    akey = str(environ.get("ANTHROPIC_API_KEY", "")).strip();
    issues_ttl = 90;
    digest_ttl = 3600;

    latest_intel = None;
    for n in [root -->][?:IssueIntelligenceNode] {
        if str(n.repo_full_name) != str(slug) {
            continue;
        }
        if latest_intel is None {
            latest_intel = n;
        } else {
            prev = latest_intel;
            p_ts = int(str(getattr(prev, "issues_fetched_at", "0") or "0"));
            n_ts = int(str(getattr(n, "issues_fetched_at", "0") or "0"));
            if p_ts < n_ts {
                latest_intel = n;
            }
        }
    }

    gh_issues: list = [];
    issues_error = "";
    fetched_from_api = False;
    if not token {
        issues_error = "Set GITHUB_TOKEN to load live issues.";
    } else {
        use_snap = False;
        if latest_intel is not None and issues_fetch_cache_fresh(
            issues_fetched_at=str(getattr(latest_intel, "issues_fetched_at", "")),
            now_ts=now_ts,
            ttl_seconds=issues_ttl
        ) {
            use_snap = True;
        }
        if use_snap {
            snap = getattr(latest_intel, "issues_snapshot", None);
            if snap {
                for row in snap {
                    gh_issues.append(row);
                }
            }
        } else {
            gh_issues = list_open_issues(repo_name=slug, limit=100);
            fetched_from_api = True;
        }
    }

    fp = issues_fingerprint_from_list(issues=gh_issues);
    digest: dict = {};
    digest_error = "";
    digest_cached = False;
    digest_from_runtime = False;
    if latest_intel is not None and str(fp) == str(getattr(latest_intel, "issues_fingerprint", "")) and issue_digest_cache_fresh(
        digest_fetched_at=str(getattr(latest_intel, "digest_fetched_at", "")),
        now_ts=now_ts,
        ttl_seconds=digest_ttl
    ) {
        dnew = getattr(latest_intel, "digest", {});
        if isinstance(dnew, dict) {
            digest = dnew;
        }
        digest_cached = True;
    }
    if (not digest_cached) and akey and len(gh_issues) > 0 {
        outline_parts: list = [];
        for it in gh_issues {
            if not it {
                continue;
            }
            labs = it.get("labels", []);
            lab_join = ",".join([str(x) for x in labs]);
            outline_parts.append(
                str(it.get("number", "")) + "\t" + str(it.get("title", ""))[:180] + "\t" + lab_join
            );
        }
        outline = "\n".join(outline_parts);
        try {
            raw_d = self._digest_open_issues(compact_outline=outline);
            if raw_d and isinstance(raw_d, dict) {
                digest = raw_d;
            }
        } except Exception as e { # jac:ignore[W2052]
            digest_error = str(e);
            digest = {
                "summary": "",
                "recommended": [],
                "clusters": [],
                "_llm_failed": True,
                "error_detail": str(e)
            };
        }
        digest_from_runtime = True;
    }

    should_persist = fetched_from_api or (digest_from_runtime and akey and len(gh_issues) > 0);
    if should_persist {
        if_ts = str(now_ts);
        if not fetched_from_api {
            if_ts = str(getattr(latest_intel, "issues_fetched_at", str(now_ts)));
        }
        df_ts = str(now_ts);
        if not (digest_from_runtime and akey and len(gh_issues) > 0) {
            df_ts = str(getattr(latest_intel, "digest_fetched_at", str(now_ts)));
        }
        _ = (
            root
            ++> IssueIntelligenceNode(
                repo_full_name=slug,
                issues_fetched_at=if_ts,
                issues_snapshot=gh_issues,
                issues_fingerprint=fp,
                digest=digest,
                digest_fetched_at=df_ts
            )
        )[0];
    }

    github_rows: list = [];
    for it in gh_issues {
        if not it {
            continue;
        }
        labs = it.get("labels", []);
        ls = ", ".join([str(x) for x in labs]);
        github_rows.append(
            {
                "id": str(it.get("number", "")),
                "title": str(it.get("title", "")),
                "labels": ls,
                "state": str(it.get("state", "open"))
            }
        );
    }

    issues_meta = {
        "truncated": len(gh_issues) >= 100,
        "count": len(gh_issues),
        "digest_stale": not (digest_cached or digest_from_runtime)
    };

    report {
        "nodes": self.nodes_data,
        "edges": self.edges_data,
        "has_graph": self.has_graph,
        "latest_analysis": self.latest_pr,
        "latest_incident": self.latest_incident,
        "latest_gap_analysis": self.latest_gap,
        "demo_repo_url": _demo_u,
        "demo_repo_slug": ghostwatch_demo_repo_slug(_demo_u),
        "github_issues": github_rows,
        "issue_digest": digest,
        "issues_meta": issues_meta,
        "issues_error": issues_error,
        "digest_error": digest_error
    };
}
