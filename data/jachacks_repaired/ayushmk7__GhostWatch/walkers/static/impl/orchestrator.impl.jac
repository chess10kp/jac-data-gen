# walkers/static/impl/orchestrator.impl.jac
import from graph.nodes { FileNode, PRAnalysisNode }
import from objects.verdict { VerdictObject }
import from walkers.static.security { SecurityAuditorWalker }
import from walkers.static.compatibility { CompatibilityCheckerWalker }
import from walkers.static.blast_radius { BlastRadiusMapperWalker }
import from integrations.github { fetch_pr_diff }
import from integrations.discord { notify_discord }

impl OrchestratorWalker.orchestrate with Root entry {
    try {
        pr_diff = fetch_pr_diff(self.pr_url);
    } except Exception as e { # jac:ignore[W2052]
        report {"error": f"Failed to fetch PR diff: {e}", "status": "failed"};
        return;
    }

    allowed_nodes = self._build_allowed_nodes(pr_diff.changed_files);
    start_node = self._get_subgraph_root();
    if not start_node {
        report {
            "error": "No graph built. Call POST /walker/GraphBuilderWalker first.",
            "status": "failed"
        };
        return;
    }

    sec_result: any = self._run_security(
        start_node, allowed_nodes, pr_diff.unified_diff
    );
    com_result: any = self._run_compat(
        start_node, allowed_nodes, pr_diff.changed_apis, pr_diff.unified_diff
    );
    bla_result: any = self._run_blast(start_node, pr_diff.changed_files);

    verdict: any = None;
    try {
        verdict = self._merge_findings(
            security=sec_result,
            compat=com_result,
            blast=bla_result,
            pr_url=self.pr_url
        );
        # Always override traversal_paths — LLM does not reliably populate this field
        verdict.traversal_paths = {
            "security": sec_result.get("traversal_path", []),
            "compatibility": com_result.get("traversal_path", []),
            "blast_radius": bla_result.get("traversal_path", [])
        };
    } except Exception as e { # jac:ignore[W2052]
        print(f"Merge findings LLM call failed: {e}");
        verdict = VerdictObject(
            overall_risk="unknown",
            risk_score=bla_result.get("risk_score", 0),
            security_findings=sec_result.get("findings", []),
            compatibility_issues=com_result.get("findings", []),
            affected_node_count=bla_result.get("affected_count", 0),
            blast_radius_summary=f"Affected {bla_result.get('affected_count', 0)} nodes",
            recommendation="Manual review required — analysis merge failed",
            traversal_paths={
                "security": sec_result.get("traversal_path", []),
                "compatibility": com_result.get("traversal_path", []),
                "blast_radius": bla_result.get("traversal_path", [])
            }
        );
    }

    import from datetime { datetime }
    now: any = datetime.now();
    pr_node = (
        root ++> PRAnalysisNode(
            pr_url=self.pr_url, verdict=dict(vars(verdict)), created_at=str(now)
        )
    )[0];

    pr_parts = self.pr_url.rstrip("/").split("/");
    pr_number = pr_parts[-1];
    verdict_map = dict(vars(verdict));
    derived_risk = self._derive_risk_label(verdict=verdict_map);
    verdict_map["overall_risk"] = derived_risk;
    pr_node.verdict = verdict_map;
    notify_discord(pr_number, derived_risk, self._discord_summary(pr_url=self.pr_url, verdict=verdict_map));

    self.verdict = verdict_map;
    report self.verdict;
}

impl OrchestratorWalker._run_security(
    start_node: FileNode, allowed_nodes: set[str], diff: str
) -> dict[str, any] {
    result: any = start_node spawn SecurityAuditorWalker(
        allowed_nodes=allowed_nodes, pr_context=diff
    );
    return {
        "findings": getattr(result, "findings", []),
        "traversal_path": getattr(result, "traversal_path", [])
    };
}

impl OrchestratorWalker._run_compat(
    start_node: FileNode, allowed_nodes: set[str], changed_apis: list[str], diff: str
) -> dict[str, any] {
    result: any = start_node spawn CompatibilityCheckerWalker(
        allowed_nodes=allowed_nodes, changed_apis=changed_apis, pr_diff=diff
    );
    return {
        "findings": getattr(result, "findings", []),
        "traversal_path": getattr(result, "traversal_path", [])
    };
}

impl OrchestratorWalker._run_blast(start_node: FileNode, changed_paths: list[str]) -> dict[str, any] {
    result: any = root spawn BlastRadiusMapperWalker(changed_nodes=changed_paths);
    affected: any = getattr(result, "affected_nodes", []);
    return {
        "affected_nodes": affected,
        "risk_score": getattr(result, "risk_score", 0),
        "traversal_path": getattr(result, "traversal_path", []),
        "affected_count": len(affected)
    };
}

impl OrchestratorWalker._get_subgraph_root() -> FileNode | None {
    nodes = [root-->][?:FileNode];
    if nodes {
        return nodes[0];
    }
    return None;
}

impl OrchestratorWalker._build_allowed_nodes(changed_files: list[str]) -> set[str] {
    import from graph.edges { ImportEdge }
    allowed = set();
    all_file_nodes = [root-->][?:FileNode];
    changed_node_ids: set = set();
    for node in all_file_nodes {
        if node.path in changed_files {
            allowed.add(jid(node));
            changed_node_ids.add(jid(node));
        }
    }
    # Extend allowed set to include direct neighbors via Python-level edge access
    for node in all_file_nodes {
        if jid(node) in changed_node_ids {
            node_any: any = node;
            for edge in node_any.__jac__.edges {
                target_anchor: any = edge.target;
                if target_anchor is not None {
                    target_node: any = target_anchor.archetype;
                    if isinstance(target_node, FileNode) {
                        allowed.add(jid(target_node));
                    }
                }
            }
        }
    }
    return allowed;
}

impl OrchestratorWalker._derive_risk_label(verdict: dict[str, any]) -> str {
    stated = str(verdict.get("overall_risk", "") or "").strip().lower();
    if stated and stated not in ["unknown", "?", "none"] {
        return stated;
    }

    sec = verdict.get("security_findings", []) or [];
    compat = verdict.get("compatibility_issues", []) or [];
    score = int(verdict.get("risk_score", 0) or 0);
    affected = int(verdict.get("affected_node_count", 0) or 0);

    has_critical = False;
    has_high = False;
    has_medium = False;
    for finding in sec {
        sev = str(finding.get("severity", "") or "").strip().lower();
        if sev == "critical" {
            has_critical = True;
        } elif sev == "high" {
            has_high = True;
        } elif sev == "medium" {
            has_medium = True;
        }
    }

    if has_critical {
        return "critical";
    }
    if has_high or score >= 30 {
        return "high";
    }
    if has_medium or len(compat) > 0 or score >= 12 {
        return "medium";
    }
    if len(sec) == 0 and len(compat) == 0 and affected == 0 and score == 0 {
        return "clean";
    }
    return "low";
}

impl OrchestratorWalker._discord_summary(pr_url: str, verdict: dict[str, any]) -> str {
    sec = verdict.get("security_findings", []) or [];
    compat = verdict.get("compatibility_issues", []) or [];
    score = int(verdict.get("risk_score", 0) or 0);
    affected = int(verdict.get("affected_node_count", 0) or 0);
    blast = str(verdict.get("blast_radius_summary", "") or "").strip();
    rec = str(verdict.get("recommendation", "") or "").strip();
    parts = pr_url.rstrip("/").split("/");
    pr_ref = "#" + str(parts[-1]) if len(parts) > 0 else pr_url;

    blast_line = blast if blast else f"Affected {affected} nodes.";
    rec_line = rec if rec else "Review manually.";
    summary = (
        f"Summary: {pr_ref} touched {affected} nodes with score {score}.\n"
        + f"Findings: {len(sec)} security, {len(compat)} compatibility.\n"
        + f"Blast radius: {blast_line}\n"
        + f"Recommendation: {rec_line}"
    );
    return summary;
}
