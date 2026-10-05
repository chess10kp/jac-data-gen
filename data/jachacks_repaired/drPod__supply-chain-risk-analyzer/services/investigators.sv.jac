import from byllm.lib { Model }
import from services.graph_store {
    lookup_vulns as store_lookup_vulns,
    count_vulns_by_severity as store_count_vulns_by_severity,
    get_dependents as store_get_dependents,
    compute_blast_radius as store_compute_blast_radius,
    get_dependencies as store_get_dependencies,
    get_dep_chain_depth as store_get_dep_chain_depth,
    get_package_stats as store_get_package_stats
}

glob llm: Model = Model(model_name="claude-haiku-4-5-20251001");

# ── Tool Functions (called by LLM agents) ────────

"""Look up all known vulnerabilities for an npm package. Returns CVE IDs, severity, and descriptions."""
def lookup_vulns(package_name: str) -> str {
    return store_lookup_vulns(package_name);
}

"""Count vulnerabilities by severity level for a package."""
def count_vulns_by_severity(package_name: str) -> str {
    return store_count_vulns_by_severity(package_name);
}

"""Get all packages that directly depend on this package (reverse dependencies)."""
def get_dependents(package_name: str) -> str {
    return store_get_dependents(package_name);
}

"""Compute the blast radius if this package were compromised. Returns affected package count and total weekly downloads at risk."""
def compute_blast_radius(package_name: str) -> str {
    return store_compute_blast_radius(package_name);
}

"""Get all direct dependencies of a package (what it depends on)."""
def get_dependencies(package_name: str) -> str {
    return store_get_dependencies(package_name);
}

"""Calculate the maximum depth of the transitive dependency chain for a package."""
def get_dep_chain_depth(package_name: str) -> str {
    return store_get_dep_chain_depth(package_name);
}

"""Get package statistics: downloads, dependents, risk score, and ecosystem position."""
def get_package_stats(package_name: str) -> str {
    return store_get_package_stats(package_name);
}

# ── LLM-Powered Agent Functions ──────────────────

sem investigate_vulns_fn = """
You are a vulnerability analyst for npm packages.
Use your tools to look up all known vulnerabilities for the given package.
Produce a concise finding (3-5 sentences) covering: total CVE count,
severity breakdown, most concerning issues, and whether this package
is actively maintained against security threats.
""";

def investigate_vulns_fn(package_name: str) -> str
    by llm(tools=[lookup_vulns, count_vulns_by_severity]);

sem investigate_blast_fn = """
You are a blast radius analyst for npm supply chain security.
Use your tools to determine the impact if this package were compromised.
Produce a concise finding (3-5 sentences) covering: number of affected packages,
total weekly downloads at risk, notable high-profile dependents,
and the severity of the supply chain exposure.
""";

def investigate_blast_fn(package_name: str) -> str
    by llm(tools=[get_dependents, compute_blast_radius]);

sem investigate_deps_fn = """
You are a dependency chain auditor for npm packages.
Use your tools to analyze the dependency tree of this package.
Produce a concise finding (3-5 sentences) covering: dependency count,
chain depth, any concerning transitive dependencies,
and whether the dependency tree is lean or bloated.
""";

def investigate_deps_fn(package_name: str) -> str
    by llm(tools=[get_dependencies, get_dep_chain_depth]);

sem investigate_maintainer_fn = """
You are a maintainer risk assessor for npm supply chain security.
Use your tools to evaluate the maintenance health of this package.
Produce a concise finding (3-5 sentences) covering: download volume,
ecosystem importance (based on dependent count), risk score relative
to other packages, and whether this is a single point of failure.
""";

def investigate_maintainer_fn(package_name: str) -> str
    by llm(tools=[get_package_stats, get_dependents]);

sem synthesize_fn = """
You are a senior security analyst producing a final threat assessment.
You receive investigation findings from 4 specialist agents:
- Vulnerability Scanner findings
- Blast Radius analysis
- Dependency Chain audit
- Maintainer Risk assessment

Synthesize all findings into a strategic threat assessment (5-7 sentences).
Assign an overall threat level (CRITICAL / HIGH / MODERATE / LOW).
End with a specific, actionable recommendation.
""";

def synthesize_fn(
    package_name: str,
    vuln_finding: str,
    blast_finding: str,
    dep_finding: str,
    maintainer_finding: str
) -> str by llm();

# ── Public API Endpoints ─────────────────────────

def:pub investigate_vulns(package_name: str) -> dict {
    try {
        finding = investigate_vulns_fn(package_name);
        return {"agent": "vulns", "status": "complete", "finding": finding};
    } except Exception as e {
        return {"agent": "vulns", "status": "error", "finding": str(e)};
    }
}

def:pub investigate_blast(package_name: str) -> dict {
    try {
        finding = investigate_blast_fn(package_name);
        return {"agent": "blast", "status": "complete", "finding": finding};
    } except Exception as e {
        return {"agent": "blast", "status": "error", "finding": str(e)};
    }
}

def:pub investigate_deps(package_name: str) -> dict {
    try {
        finding = investigate_deps_fn(package_name);
        return {"agent": "deps", "status": "complete", "finding": finding};
    } except Exception as e {
        return {"agent": "deps", "status": "error", "finding": str(e)};
    }
}

def:pub investigate_maintainer(package_name: str) -> dict {
    try {
        finding = investigate_maintainer_fn(package_name);
        return {"agent": "maintainer", "status": "complete", "finding": finding};
    } except Exception as e {
        return {"agent": "maintainer", "status": "error", "finding": str(e)};
    }
}

def:pub investigate_synthesize(
    package_name: str,
    vuln_finding: str,
    blast_finding: str,
    dep_finding: str,
    maintainer_finding: str
) -> dict {
    try {
        finding = synthesize_fn(
            package_name=package_name,
            vuln_finding=vuln_finding,
            blast_finding=blast_finding,
            dep_finding=dep_finding,
            maintainer_finding=maintainer_finding
        );
        return {"agent": "synthesis", "status": "complete", "finding": finding};
    } except Exception as e {
        return {"agent": "synthesis", "status": "error", "finding": str(e)};
    }
}
