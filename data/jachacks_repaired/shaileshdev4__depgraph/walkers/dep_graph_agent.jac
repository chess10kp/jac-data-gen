"""Main orchestrator — manifest ingest, graph build, spawn subtree walkers."""

import from ..graph.nodes { InvestigationSession, Package, CVE }
import from ..graph.builder { build_package_graph }
import from ..graph.snapshot_util {
    build_graph_snapshot,
    pkg_node_id,
    severity_from_cvss
}
import from ..tools.jac_coerce { as_list }
import from ..tools.manifest_resolver {
    fetch_ecosystem_manifest,
    parse_ecosystem_manifest
}
import from ..tools.risk_scorer { package_risk_score }
import from walkers.remediation_walker { RemediationWalker }
import from walkers.report_util { generate_executive_summary_safe }
import from walkers.route_util { select_spawn_root_index }
import from walkers.subtree_walker { SubtreeWalker }
import from walkers.usage_context_util {
    package_usage_surface,
    compute_exploitability,
    package_has_usage_context,
    attach_usage_context_for_package,
    refresh_findings_usage,
    is_workspace_package,
}
import from ..tools.investigation_runner { session_push }

def _spawn_roots_fallback(candidates: list[Package], pick_count: int) -> list[Package] {
    if len(candidates) <= pick_count {
        return candidates;
    }
    selected: list[Package] = [];
    selected_names: dict = {};
    picks = 0;
    while picks < pick_count {
        best_idx = -1;
        best_score = -1;
        idx = 0;
        for pkg_node in candidates {
            if pkg_node.name in selected_names {
                idx += 1;
                continue;
            }
            score = package_risk_score(
                pkg_node.name,
                pkg_node.version,
                pkg_node.depth,
                pkg_node.is_direct
            );
            if score > best_score {
                best_score = score;
                best_idx = idx;
            }
            idx += 1;
        }
        if best_idx < 0 {
            break;
        }
        chosen = candidates[best_idx];
        selected.append(chosen);
        selected_names[chosen.name] = True;
        picks += 1;
    }
    return selected;
}

def _top_risk_candidates(
    candidates: list[Package],
    limit: int
) -> list[Package] {
    if len(candidates) <= limit {
        return candidates;
    }
    return _spawn_roots_fallback(candidates, limit);
}

walker:pub DepGraphAgent {
    has repo_url: str;
    has ecosystem: str = "npm";
    has max_direct_deps: int = 8;
    has max_graph_packages: int = 300;
    has max_spawn_llm_pool: int = 30;
    has session_id: str = "";
    has reports: list[dict] = [];

    can start with Root entry {
        manifest_result = fetch_ecosystem_manifest(
            self.repo_url,
            self.ecosystem
        );
        if not manifest_result["ok"] {
            err_msg = str(manifest_result.get("error", "manifest fetch failed"));
            report {"event": "error", "message": err_msg};
            if self.session_id {
                session_push(
                    self.session_id,
                    {"event": "error", "message": err_msg}
                );
            }
            disengage;
        }

        active_ecosystem = self.ecosystem;
        if "ecosystem" in manifest_result {
            active_ecosystem = str(manifest_result["ecosystem"]);
        }
        if active_ecosystem == "auto" {
            active_ecosystem = "npm";
        }

        session = InvestigationSession(
            repo_url=self.repo_url,
            ecosystem=active_ecosystem,
            status="running"
        );
        root ++> session;
        report {
            "event": "session_started",
            "repo_url": self.repo_url,
            "ecosystem": active_ecosystem,
            "session_id": self.session_id
        };
        if self.session_id {
            session_push(
                self.session_id,
                {
                    "event": "session_started",
                    "repo_url": self.repo_url,
                    "ecosystem": active_ecosystem,
                    "session_id": self.session_id
                }
            );
        }

        manifest_kind = str(manifest_result.get("manifest_kind", "lockfile"));
        report {
            "event": "lockfile_fetched",
            "owner": manifest_result["owner"],
            "repo": manifest_result["repo"],
            "filename": manifest_result["filename"],
            "manifest_kind": manifest_kind,
            "ecosystem": active_ecosystem
        };
        if self.session_id {
            session_push(
                self.session_id,
                {
                    "event": "lockfile_fetched",
                    "owner": manifest_result["owner"],
                    "repo": manifest_result["repo"],
                    "filename": manifest_result["filename"],
                    "manifest_kind": manifest_kind,
                    "ecosystem": active_ecosystem
                }
            );
        }

        manifest_text: str = str(manifest_result["text"]);
        report {
            "event": "manifest_parsing",
            "filename": manifest_result["filename"],
            "bytes": len(manifest_text),
            "ecosystem": active_ecosystem
        };
        parsed = parse_ecosystem_manifest(
            manifest_text,
            active_ecosystem,
            manifest_kind,
            self.max_graph_packages
        );
        if not parsed["ok"] {
            report {"event": "error", "message": parsed["error"]};
            disengage;
        }
        truncated = False;
        if "truncated" in parsed {
            truncated = parsed["truncated"];
        }
        filter_method = "none";
        if "filter_method" in parsed {
            filter_method = str(parsed["filter_method"]);
        }
        original_cnt = parsed["package_count"];
        if "original_package_count" in parsed {
            original_cnt = parsed["original_package_count"];
        }
        report {
            "event": "manifest_parsed",
            "package_count": parsed["package_count"],
            "truncated": truncated,
            "original_package_count": original_cnt,
            "filter_method": filter_method
        };

        pkg_count = build_package_graph(session, parsed);
        edge_list = as_list(parsed.get("edges", []));
        edge_cnt = 0;
        for _x in edge_list {
            edge_cnt += 1;
        }
        report {
            "event": "graph_built",
            "package_count": pkg_count,
            "edge_count": edge_cnt,
            "truncated": truncated,
            "filter_method": filter_method
        };

        session_packages: list[Package] = [];
        for pkg_node in [session-->][?:Package] {
            session_packages.append(pkg_node);
        }
        snapshot = build_graph_snapshot(session_packages, parsed, []);
        report {
            "event": "graph_snapshot",
            "nodes": snapshot["nodes"],
            "edges": snapshot["edges"],
            "package_count": pkg_count,
            "edge_count": edge_cnt
        };
        if self.session_id {
            session_push(
                self.session_id,
                {
                    "event": "graph_snapshot",
                    "nodes": snapshot["nodes"],
                    "edges": snapshot["edges"],
                    "package_count": pkg_count,
                    "edge_count": edge_cnt
                }
            );
        }

        candidates: list[Package] = [];
        for pkg_node in [session-->][?:Package] {
            if is_workspace_package(pkg_node, self.repo_url) {
                continue;
            }
            if pkg_node.is_direct and pkg_node.depth <= 1 {
                candidates.append(pkg_node);
            }
        }
        if not candidates {
            for pkg_node in [session-->][?:Package] {
                if pkg_node.depth == 0 {
                    continue;
                }
                candidates.append(pkg_node);
            }
        }

        spawn_pool = _top_risk_candidates(
            candidates,
            self.max_spawn_llm_pool
        );

        spawn_targets: list[Package] = [];
        spawn_mode = "fallback";
        llm_spawn_picks = 0;
        spawn_llm_failures = 0;
        remaining_pool: list[Package] = [];
        for pkg_node in spawn_pool {
            remaining_pool.append(pkg_node);
        }

        report {
            "event": "spawn_decision",
            "candidate_count": len(candidates),
            "llm_pool_count": len(spawn_pool),
            "pick_count": self.max_direct_deps,
            "message": "LLM selecting subtree spawn roots from top risk pool"
        };

        while (
            len(spawn_targets) < self.max_direct_deps
            and len(remaining_pool) > 0
        ) {
            descriptions = "";
            slot = 0;
            for pkg_node in remaining_pool {
                descriptions = (
                    f"{descriptions}{slot}) {pkg_node.name}\n"
                );
                slot += 1;
            }

            picked_idx = -1;
            spawn_err = "";
            attempts = 0;
            while attempts < 2 and picked_idx < 0 {
                attempts += 1;
                try {
                    raw_spawn = select_spawn_root_index(descriptions);
                    if raw_spawn and len(raw_spawn) >= 1 {
                        pick = raw_spawn[0];
                        if pick >= 0 and pick < len(remaining_pool) {
                            picked_idx = pick;
                        }
                    }
                } except Exception as e {
                    spawn_err = str(e);
                }
            }
            if picked_idx < 0 {
                spawn_llm_failures += 1;
                risk_one = _spawn_roots_fallback(remaining_pool, 1);
                if not risk_one {
                    break;
                }
                chosen = risk_one[0];
            } else {
                chosen = remaining_pool[picked_idx];
                llm_spawn_picks += 1;
            }
            spawn_targets.append(chosen);
            next_pool: list[Package] = [];
            for pkg_node in remaining_pool {
                if pkg_node.name != chosen.name {
                    next_pool.append(pkg_node);
                }
            }
            remaining_pool = next_pool;
        }

        if llm_spawn_picks > 0 {
            spawn_mode = "llm";
        }
        if spawn_llm_failures > 0 and llm_spawn_picks == 0 {
            report {
                "event": "spawn_llm_failed",
                "reason": "All spawn LLM picks failed",
                "failures": spawn_llm_failures
            };
        } elif spawn_llm_failures > 0 {
            report {
                "event": "spawn_llm_partial",
                "llm_picks": llm_spawn_picks,
                "risk_picks": spawn_llm_failures,
                "message": "Some spawn picks used risk fallback after LLM empty response"
            };
        }
        if len(spawn_targets) < self.max_direct_deps {
            picked_names: dict = {};
            for pkg_node in spawn_targets {
                picked_names[pkg_node.name] = True;
            }
            extra_pool: list[Package] = [];
            for pkg_node in candidates {
                if pkg_node.name not in picked_names {
                    extra_pool.append(pkg_node);
                }
            }
            need = self.max_direct_deps - len(spawn_targets);
            extras = _spawn_roots_fallback(extra_pool, need);
            for pkg_node in extras {
                spawn_targets.append(pkg_node);
            }
            if llm_spawn_picks == 0 {
                spawn_mode = "fallback";
            }
        }

        spawned_names = "";
        for pkg_node in spawn_targets {
            spawned_names = f"{spawned_names}{pkg_node.name} ";
        }
        spawn_root_ids: list[str] = [];
        for pkg_node in spawn_targets {
            spawn_root_ids.append(pkg_node_id(pkg_node.name, pkg_node.version));
        }
        snapshot_after = build_graph_snapshot(
            session_packages,
            parsed,
            spawn_root_ids
        );
        report {
            "event": "spawn_roots",
            "roots": spawn_root_ids
        };
        if self.session_id {
            session_push(
                self.session_id,
                {
                    "event": "spawn_roots",
                    "roots": spawn_root_ids
                }
            );
        }
        report {
            "event": "graph_snapshot",
            "nodes": snapshot_after["nodes"],
            "edges": snapshot_after["edges"],
            "package_count": pkg_count,
            "edge_count": edge_cnt
        };
        if self.session_id {
            session_push(
                self.session_id,
                {
                    "event": "graph_snapshot",
                    "nodes": snapshot_after["nodes"],
                    "edges": snapshot_after["edges"],
                    "package_count": pkg_count,
                    "edge_count": edge_cnt
                }
            );
        }

        report {
            "event": "spawn_chosen",
            "mode": spawn_mode,
            "targets": spawned_names.strip(),
            "count": len(spawn_targets),
            "llm_picks": llm_spawn_picks,
            "risk_picks": spawn_llm_failures
        };
        if self.session_id {
            session_push(
                self.session_id,
                {
                    "event": "spawn_chosen",
                    "mode": spawn_mode,
                    "targets": spawned_names.strip(),
                    "count": len(spawn_targets),
                    "llm_picks": llm_spawn_picks,
                    "risk_picks": spawn_llm_failures
                }
            );
        }

        for pkg_node in spawn_targets {
            attach_usage_context_for_package(
                self.repo_url,
                pkg_node,
                self.session_id,
                session_packages
            );
        }

        spawned = 0;
        lookup_count = 0;
        route_llm_count = 0;
        route_fallback_count = 0;
        deep_dive_names: dict = {};
        for pkg_node in spawn_targets {
            subtree = SubtreeWalker(
                depth_limit=3,
                max_visits=5,
                session_id=self.session_id,
                repo_url=self.repo_url,
                session_packages=session_packages,
                ecosystem=active_ecosystem
            ) spawn pkg_node;
            sub_lookups = subtree.osv_lookup_count;
            for ent in subtree.reports {
                report ent;
                if "event" in ent {
                    ev_name = str(ent["event"]);
                    if ev_name == "route_chosen" {
                        rmode = str(ent.get("mode", "fallback"));
                        if rmode == "llm" {
                            route_llm_count += 1;
                        } else {
                            route_fallback_count += 1;
                        }
                    }
                    if ev_name == "deep_dive" {
                        dp = str(ent.get("package", ""));
                        if dp {
                            deep_dive_names[dp] = True;
                        }
                    }
                }
                if sub_lookups == 0 and "event" in ent {
                    if ent["event"] == "nvd_lookup" {
                        sub_lookups += 1;
                    }
                }
            }
            lookup_count += sub_lookups;
            spawned += 1;
        }

        for pkg_node in session_packages {
            cve_nodes = [pkg_node-->][?:CVE];
            if not cve_nodes {
                continue;
            }
            if package_has_usage_context(pkg_node) {
                continue;
            }
            attach_usage_context_for_package(
                self.repo_url,
                pkg_node,
                self.session_id,
                session_packages
            );
        }

        for pkg_node in session_packages {
            cve_nodes = [pkg_node-->][?:CVE];
            if not cve_nodes {
                continue;
            }
            if package_usage_surface(pkg_node) != "unknown" {
                continue;
            }
            attach_usage_context_for_package(
                self.repo_url,
                pkg_node,
                self.session_id,
                session_packages
            );
        }

        report {
            "event": "subtrees_spawned",
            "spawn_count": spawned,
            "max_direct_deps": self.max_direct_deps,
            "spawn_mode": spawn_mode
        };

        findings: list[dict] = [];
        for pkg_node in [session-->][?:Package] {
            cve_nodes = [pkg_node-->][?:CVE];
            if not cve_nodes {
                continue;
            }
            max_cvss = 0.0;
            top_cve = "";
            fixed_version = "";
            for cve_node in cve_nodes {
                if cve_node.cvss_score > max_cvss {
                    max_cvss = cve_node.cvss_score;
                    top_cve = cve_node.cve_id;
                }
                if cve_node.fixed_version and not fixed_version {
                    fixed_version = str(cve_node.fixed_version);
                }
            }
            finding_surface = package_usage_surface(pkg_node);
            findings.append(
                {
                    "package": pkg_node.name,
                    "version": pkg_node.version,
                    "cve_count": len(cve_nodes),
                    "max_cvss": max_cvss,
                    "top_cve": top_cve,
                    "severity": severity_from_cvss(max_cvss),
                    "depth": pkg_node.depth,
                    "is_direct": pkg_node.is_direct,
                    "deep_dive_triggered": pkg_node.name in deep_dive_names,
                    "fixed_version": fixed_version,
                    "usage_surface": finding_surface,
                    "exploitability": compute_exploitability(
                        max_cvss,
                        finding_surface
                    )
                }
            );
        }

        for item in findings {
            pkg_name = str(item["package"]);
            for pkg_node in session_packages {
                if pkg_node.name != pkg_name {
                    continue;
                }
                if str(pkg_node.version) != str(item["version"]) {
                    continue;
                }
                if not package_has_usage_context(pkg_node) {
                    attach_usage_context_for_package(
                        self.repo_url,
                        pkg_node,
                        self.session_id,
                        session_packages
                    );
                }
                break;
            }
        }
        refresh_findings_usage(findings, session_packages);

        for pkg_node in [session-->][?:Package] {
            cve_nodes = [pkg_node-->][?:CVE];
            if not cve_nodes {
                continue;
            }
            remed = RemediationWalker() spawn pkg_node;
            for ent in remed.reports {
                report ent;
            }
        }

        findings_lines = "";
        for item in findings {
            findings_lines = (
                f"{findings_lines}{item['package']}@{item['version']} "
                f"cvss={item['max_cvss']} exploitability={item['exploitability']} "
                f"surface={item['usage_surface']} ({item['top_cve']})\n"
            );
        }
        if not findings_lines {
            findings_lines = "No vulnerable packages in scanned subtrees.";
        }
        critical_count = 0;
        for item in findings {
            if item["max_cvss"] >= 9.0 {
                critical_count += 1;
            }
        }

        report {"event": "report_generating"};
        summary = "";
        try {
            summary = generate_executive_summary_safe(
                self.repo_url,
                findings_lines,
                lookup_count,
                len(findings)
            );
        } except Exception {
            summary = (
                f"Scanned {lookup_count} packages across {spawned} subtrees. "
                f"Found {len(findings)} vulnerable package(s)."
            );
        }
        report {
            "event": "report_generated",
            "summary": summary
        };

        report {
            "event": "investigation_complete",
            "packages_scanned": lookup_count,
            "packages_in_graph": pkg_count,
            "subtrees_spawned": spawned,
            "vulnerable_count": len(findings),
            "critical_count": critical_count,
            "spawn_mode": spawn_mode,
            "route_llm_count": route_llm_count,
            "route_fallback_count": route_fallback_count,
            "truncated": truncated,
            "original_package_count": original_cnt,
            "findings": findings,
            "executive_summary": summary
        };
        if self.session_id {
            session_push(
                self.session_id,
                {
                    "event": "investigation_complete",
                    "packages_scanned": lookup_count,
                    "packages_in_graph": pkg_count,
                    "subtrees_spawned": spawned,
                    "vulnerable_count": len(findings),
                    "critical_count": critical_count,
                    "spawn_mode": spawn_mode,
                    "route_llm_count": route_llm_count,
                    "route_fallback_count": route_fallback_count,
                    "truncated": truncated,
                    "original_package_count": original_cnt,
                    "findings": findings,
                    "executive_summary": summary
                }
            );
        }
    }
}
