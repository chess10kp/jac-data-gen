import from byllm.lib { Model }
import from services.graph_store {
    store_build_graph,
    store_load_scenarios,
    store_reset_graph,
    store_get_graph,
    store_infect_package,
    store_get_risk_heatmap,
    store_get_blast_radius,
    store_get_attack_scenarios
}

glob llm: Model = Model(model_name="claude-haiku-4-5-20251001");

# ── Nodes ────────────────────────────────────────────

node Package {
    has name: str;
    has weekly_downloads: int = 0;
    has maintainer_count: int = 1;
    has dependent_count: int = 0;
    has risk_score: float = 0.0;
    has blast_radius: float = 0.0;
    has cve_count: int = 0;
    has compromised: bool = False;
    has compromise_depth: int = -1;
    has threat_summary: str = "";
}

node AttackScenario {
    has scenario_id: str;
    has display_title: str;
    has year: int;
    has attack_type: str = "";
    has description: str = "";
    has affected_packages: list = [];
    has timeline: list = [];
    has blast_radius_snapshot: dict = {};
    has cascade_data: dict = {};
}

# ── Edges ────────────────────────────────────────────

edge DependsOn {
    has version_constraint: str = "*";
    has is_direct: bool = True;
}

edge HasScenario {}

# ── LLM Functions ────────────────────────────────────

sem generate_threat_report = """
You are a cybersecurity analyst assessing a simulated npm supply chain attack.
Given the attack data, produce a concise threat report (4-6 sentences).
Cover: severity, blast radius, real-world impact on developers, and a mitigation recommendation.
Be dramatic but factual. Use specific numbers from the input.
""";

def generate_threat_report(
    target_package: str,
    compromised_count: int,
    affected_weekly_downloads: int,
    max_depth: int,
    sample_compromised_packages: list[str]
) -> str by llm();

# ── Helper Functions ─────────────────────────────────

def get_or_create_package(
    name: str,
    weekly_downloads: int = 0,
    maintainer_count: int = 1,
    dependent_count: int = 0,
    risk_score: float = 0.0,
    blast_radius: float = 0.0,
    cve_count: int = 0
) -> Package {
    for pkg in [root()-->][?:Package] {
        if pkg.name == name {
            if weekly_downloads > 0 { pkg.weekly_downloads = weekly_downloads; }
            if maintainer_count > 0 { pkg.maintainer_count = maintainer_count; }
            if dependent_count > 0 { pkg.dependent_count = dependent_count; }
            if risk_score > 0.0 { pkg.risk_score = risk_score; }
            if blast_radius > 0.0 { pkg.blast_radius = blast_radius; }
            if cve_count > 0 { pkg.cve_count = cve_count; }
            return pkg;
        }
    }
    return (root() ++> Package(
        name=name,
        weekly_downloads=weekly_downloads,
        maintainer_count=maintainer_count,
        dependent_count=dependent_count,
        risk_score=risk_score,
        blast_radius=blast_radius,
        cve_count=cve_count
    ))[0];
}

def package_to_dict(pkg: Package) -> dict {
    dependencies = [{
        "name": dep.name,
        "version_constraint": "*",
        "is_direct": True
    } for dep in [pkg-->][?:Package]];

    dep_count = len([pkg<--][?:Package]);

    return {
        "id": jid(pkg),
        "name": pkg.name,
        "weekly_downloads": pkg.weekly_downloads,
        "maintainer_count": pkg.maintainer_count,
        "dependent_count": pkg.dependent_count if pkg.dependent_count > 0 else dep_count,
        "risk_score": pkg.risk_score,
        "blast_radius": pkg.blast_radius,
        "cve_count": pkg.cve_count,
        "compromised": pkg.compromised,
        "compromise_depth": pkg.compromise_depth,
        "threat_summary": pkg.threat_summary,
        "dependencies": dependencies
    };
}

# ── Public API Endpoints ─────────────────────────────

def:pub build_graph(packages: list[dict]) -> dict {
    return store_build_graph(packages);
}

def:pub load_scenarios(scenarios: list[dict]) -> dict {
    return store_load_scenarios(scenarios);
}

def:pub reset_graph() -> dict {
    return store_reset_graph();
}

def:pub get_graph() -> dict {
    return store_get_graph();
}

def:pub infect_package(package_name: str) -> dict {
    return store_infect_package(package_name);
}

def:pub assess_compromise(
    target: str,
    compromised_count: int,
    affected_downloads: int,
    max_depth: int,
    sample_packages: list[str]
) -> dict {
    try {
        report_text = generate_threat_report(
            target_package=target,
            compromised_count=compromised_count,
            affected_weekly_downloads=affected_downloads,
            max_depth=max_depth,
            sample_compromised_packages=sample_packages
        );
        return {"success": True, "report": report_text};
    } except Exception as e {
        return {"success": False, "error": str(e)};
    }
}

def:pub get_risk_heatmap(top_n: int = 100) -> dict {
    return store_get_risk_heatmap(top_n);
}

def:pub get_blast_radius(package_name: str) -> dict {
    return store_get_blast_radius(package_name);
}

def:pub get_attack_scenarios() -> dict {
    return store_get_attack_scenarios();
}

# ── Walkers ──────────────────────────────────────────

walker :pub BuildGraph {
    has packages: list[dict] = [];

    can build with Root entry {
        report build_graph(self.packages);
    }
}

walker :pub Infect {
    has target_name: str = "";
    has compromised_ids: list[str] = [];
    has compromised_packages: list[dict] = [];
    has total_damage: int = 0;
    has found: bool = False;

    can start with Root entry {
        for pkg in [-->][?:Package] {
            if pkg.name == self.target_name {
                self.found = True;
                visit pkg;
                return;
            }
        }
    }

    can spread with Package entry {
        if jid(here) in self.compromised_ids {
            return;
        }

        if here.compromise_depth < 0 {
            if len(self.compromised_ids) == 0 {
                here.compromise_depth = 0;
            } else {
                parent_depths = [parent.compromise_depth for parent in [-->][?:Package] if parent.compromise_depth >= 0];
                here.compromise_depth = min(parent_depths) + 1 if parent_depths else 1;
            }
        }

        here.compromised = True;
        self.compromised_ids.append(jid(here));
        self.compromised_packages.append({
            "name": here.name,
            "depth": here.compromise_depth,
            "weekly_downloads": here.weekly_downloads
        });
        self.total_damage += here.weekly_downloads;

        visit [<--][?:Package];
    }

    can finish with Root exit {
        if self.found {
            report {
                "success": True,
                "target": self.target_name,
                "compromised_count": len(self.compromised_ids),
                "affected_weekly_downloads": self.total_damage,
                "compromised_packages": self.compromised_packages
            };
        } else {
            report {"success": False, "error": "Package not found", "target": self.target_name};
        }
    }
}

walker :pub Assess {
    has assessed: int = 0;

    can start with Root entry {
        visit [-->][?:Package];
        report {"success": True, "assessed": self.assessed};
    }

    can summarize with Package entry {
        if here.compromised {
            dependent_count = len([<--][?:Package]);
            here.threat_summary = assess_package_threat(
                package_name=here.name,
                weekly_downloads=here.weekly_downloads,
                compromise_depth=here.compromise_depth,
                dependent_count=dependent_count
            );
            self.assessed += 1;
        }
    }
}

walker :pub Reset {
    has reset_count: int = 0;

    can start with Root entry {
        visit [-->][?:Package];
        report {"success": True, "reset_count": self.reset_count};
    }

    can clear with Package entry {
        here.compromised = False;
        here.compromise_depth = -1;
        here.threat_summary = "";
        self.reset_count += 1;
    }
}

walker :pub GetGraph {
    has packages: list[dict] = [];

    can start with Root entry {
        visit [-->][?:Package];
        report {
            "success": True,
            "package_count": len(self.packages),
            "packages": self.packages
        };
    }

    can collect with Package entry {
        self.packages.append(package_to_dict(here));
    }
}

walker :pub RiskHeatmap {
    has packages: list[dict] = [];

    can start with Root entry {
        visit [-->][?:Package];
    }

    can collect with Package entry {
        self.packages.append({
            "name": here.name,
            "weekly_downloads": here.weekly_downloads,
            "dependent_count": here.dependent_count,
            "risk_score": here.risk_score,
            "blast_radius": here.blast_radius,
            "cve_count": here.cve_count,
            "compromised": here.compromised,
            "compromise_depth": here.compromise_depth
        });
    }
}

walker :pub BlastRadius {
    has target_name: str = "";
    has affected: list[dict] = [];
    has visited_names: list[str] = [];
    has total_downloads: int = 0;
    has max_depth: int = 0;
    has by_depth: dict = {};
    has found: bool = False;

    can start with Root entry {
        for pkg in [-->][?:Package] {
            if pkg.name == self.target_name {
                self.found = True;
                visit pkg;
                return;
            }
        }
    }

    can propagate with Package entry {
        if here.name in self.visited_names {
            return;
        }

        depth = 0;
        if len(self.visited_names) > 0 {
            depth = self.max_depth + 1;
        }

        self.visited_names.append(here.name);
        self.affected.append({
            "name": here.name,
            "depth": depth,
            "weekly_downloads": here.weekly_downloads,
            "dependent_count": here.dependent_count,
            "risk_score": here.risk_score
        });
        self.total_downloads += here.weekly_downloads;
        if depth > self.max_depth {
            self.max_depth = depth;
        }

        depth_key = str(depth);
        if depth_key not in self.by_depth {
            self.by_depth[depth_key] = [];
        }
        self.by_depth[depth_key].append({
            "name": here.name,
            "downloads": here.weekly_downloads
        });

        # Walk reverse edges: packages that depend on this one
        visit [<--][?:Package];
    }
}

walker :pub GetScenarios {
    has scenarios: list[dict] = [];

    can start with Root entry {
        visit [-->][?:AttackScenario];
    }

    can collect with AttackScenario entry {
        self.scenarios.append({
            "id": here.scenario_id,
            "display_title": here.display_title,
            "year": here.year,
            "attack_type": here.attack_type,
            "description": here.description,
            "affected_packages": here.affected_packages,
            "timeline": here.timeline,
            "blast_radius_snapshot": here.blast_radius_snapshot,
            "cascade_data": here.cascade_data
        });
    }
}
