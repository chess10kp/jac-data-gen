"""Traverse a dependency subtree: OSV lookup + LLM Route for next hop."""

import from ..graph.nodes { Package, CVE }
import from ..tools.cve_lookup { lookup_package_cves }
import from ..tools.jac_coerce { as_list }
import from ..tools.risk_scorer { package_risk_score }
import from walkers.deep_dive_walker { DeepDiveWalker }
import from walkers.route_util { choose_neighbor_indexes }
import from walkers.usage_context_util {
    package_usage_surface,
    compute_exploitability,
    attach_usage_context_for_package,
    package_has_usage_context,
    push_live_event
}

def usage_surface_route_tag(surface: str) -> str {
    s = str(surface).lower();
    if s == "production" {
        return "[PRODUCTION - auth surface]";
    }
    if s == "test" {
        return "[TEST only]";
    }
    if s == "build" {
        return "[BUILD only]";
    }
    if s == "mixed" {
        return "[MIXED prod+test]";
    }
    return "[usage unknown]";
}

def neighbor_max_cvss(pkg_node: Package) -> float {
    best = pkg_node.cvss_score;
    for cve_node in [pkg_node-->][?:CVE] {
        if cve_node.cvss_score > best {
            best = cve_node.cvss_score;
        }
    }
    return best;
}

def pick_best_fallback_index(neighbor_list: list[Package]) -> int {
    best_idx = 0;
    best_score = -1.0;
    idx = 0;
    for pkg_node in neighbor_list {
        score = neighbor_max_cvss(pkg_node);
        if score <= 0.0 {
            score = float(
                package_risk_score(
                    pkg_node.name,
                    pkg_node.version,
                    pkg_node.depth,
                    pkg_node.is_direct
                )
            ) / 100.0;
        }
        if package_usage_surface(pkg_node) == "production" {
            score += 0.25;
        }
        if score > best_score {
            best_score = score;
            best_idx = idx;
        }
        idx += 1;
    }
    return best_idx;
}

walker SubtreeWalker {
    has depth_limit: int = 3;
    has max_visits: int = 5;
    has visit_count: int = 0;
    has osv_lookup_count: int = 0;
    has session_id: str = "";
    has repo_url: str = "";
    has session_packages: list = [];
    has ecosystem: str = "npm";
    has reports: list[dict] = [];
    has critical_findings: list[dict] = [];

    can scan with Package entry {
        if here.depth > self.depth_limit {
            disengage;
        }
        if self.visit_count >= self.max_visits {
            disengage;
        }
        self.visit_count += 1;

        self.osv_lookup_count += 1;
        nvd_lookup_evt = {
            "event": "nvd_lookup",
            "package": here.name,
            "version": here.version,
            "depth": here.depth
        };
        report nvd_lookup_evt;
        push_live_event(self.session_id, nvd_lookup_evt);

        cves = lookup_package_cves(here.name, here.version, self.ecosystem);
        max_cvss = 0.0;
        has_critical = False;
        top_cve_id = "";
        source = "osv";
        here_surface = package_usage_surface(here);

        for cve_data in cves {
            if cve_data.get("source", "") == "nvd" {
                source = "nvd";
            }
            cve_node = CVE(
                cve_id=cve_data["cve_id"],
                cvss_score=cve_data["cvss_score"],
                severity=cve_data["severity"],
                description=cve_data["description"],
                fixed_version=cve_data["fixed_version"]
            );
            here ++> cve_node;
            if cve_data["cvss_score"] >= 9.0 {
                has_critical = True;
            }
            if cve_data["cvss_score"] > max_cvss {
                max_cvss = cve_data["cvss_score"];
                top_cve_id = str(cve_data["cve_id"]);
            }
        }

        exploitability = compute_exploitability(max_cvss, here_surface);

        if has_critical and top_cve_id {
            dive = DeepDiveWalker(
                target_name=here.name,
                target_version=here.version,
                cve_id=top_cve_id,
                cvss_score=max_cvss,
                ecosystem=self.ecosystem
            ) spawn here;
            for ent in dive.reports {
                report ent;
            }
            for finding in dive.transitive_findings {
                self.critical_findings.append(finding);
            }
        }

        nvd_result_evt = {
            "event": "nvd_result",
            "package": here.name,
            "version": here.version,
            "cve_count": len(cves),
            "max_cvss": max_cvss,
            "critical": has_critical,
            "source": source,
            "usage_surface": here_surface,
            "exploitability": exploitability
        };
        report nvd_result_evt;
        push_live_event(self.session_id, nvd_result_evt);

        if len(cves) > 0 and self.repo_url {
            if not package_has_usage_context(here) {
                attach_usage_context_for_package(
                    self.repo_url,
                    here,
                    self.session_id,
                    self.session_packages
                );
            }
        }

        if self.visit_count >= self.max_visits {
            disengage;
        }

        neighbor_list: list[Package] = as_list(
            [here ->:DependsOn:->][?:Package]
        );
        neighbor_cnt = len(neighbor_list);
        if neighbor_cnt == 0 {
            disengage;
        }

        descriptions = "";
        slot = 0;
        for pkg_node in neighbor_list {
            n_cvss = neighbor_max_cvss(pkg_node);
            n_surface = package_usage_surface(pkg_node);
            n_tag = usage_surface_route_tag(n_surface);
            descriptions = (
                f"{descriptions}{slot}) {pkg_node.name}@"
                f"{pkg_node.version} {n_tag} (known_cvss={n_cvss})\n"
            );
            slot += 1;
        }

        route_decision_evt = {
            "event": "route_decision",
            "package": here.name,
            "version": here.version,
            "neighbor_count": neighbor_cnt,
            "max_cvss": max_cvss,
            "cve_count": len(cves),
            "usage_surface": here_surface,
            "exploitability": exploitability,
            "message": "LLM selecting next dependency to investigate"
        };
        report route_decision_evt;
        push_live_event(self.session_id, route_decision_evt);

        fallback_idx = pick_best_fallback_index(neighbor_list);
        pick_indexes: list[int] = [fallback_idx];
        route_mode = "fallback";

        critical_context = (
            f"Current package usage: {usage_surface_route_tag(here_surface)}. "
        );
        if exploitability != "MEDIUM" or max_cvss > 0.0 {
            critical_context = (
                f"{critical_context}Exploitability={exploitability}. "
            );
        }
        if self.critical_findings {
            critical_context = (
                f"{critical_context}TRANSITIVE CRITICAL FINDINGS: "
            );
            for f in self.critical_findings {
                pkg_name = str(f["package"]);
                cvss_val = f["cvss"];
                critical_context = (
                    f"{critical_context}{pkg_name} CVSS {cvss_val}, "
                );
            }
        }

        try {
            raw_picks = choose_neighbor_indexes(
                here.name,
                here.version,
                len(cves),
                max_cvss,
                has_critical,
                descriptions,
                critical_context
            );
            if raw_picks and len(raw_picks) == 1 {
                only = raw_picks[0];
                if only >= 0 and only < neighbor_cnt {
                    pick_indexes = [only];
                    route_mode = "llm";
                }
            } elif raw_picks and len(raw_picks) > 1 {
                route_mode = "fallback_multi";
            }
        } except Exception {
            route_mode = "fallback";
        }

        to_visit: list = [];
        for pick in pick_indexes {
            if pick >= 0 and pick < neighbor_cnt {
                to_visit.append(neighbor_list[pick]);
            }
        }
        if not to_visit {
            to_visit.append(neighbor_list[fallback_idx]);
            route_mode = "fallback";
            pick_indexes = [fallback_idx];
        }

        picked_names = "";
        for pkg_node in to_visit {
            picked_names = f"{picked_names}{pkg_node.name} ";
        }
        route_idx = 0;
        if pick_indexes {
            route_idx = pick_indexes[0];
        }
        route_chosen_evt = {
            "event": "route_chosen",
            "from_package": here.name,
            "from_version": here.version,
            "mode": route_mode,
            "index": route_idx,
            "indexes": pick_indexes,
            "targets": picked_names.strip()
        };
        report route_chosen_evt;
        push_live_event(self.session_id, route_chosen_evt);

        visit to_visit;
    }
}
