"""LLM routing — return exactly one neighbor index as JSON, e.g. [3]."""

import from ..models.llm_config { routing_llm, spawn_llm }

"""Security dependency investigator routing decision.
Current package: {current_package}@{current_version}
CVEs found on current package: {cve_count} (max CVSS: {current_cvss})
Critical CVE on current package: {has_critical}
{critical_context}

Neighbors to investigate next:
{neighbor_descriptions}

Return EXACTLY ONE index as a JSON array.
Prioritize neighbors tagged [PRODUCTION - auth surface] over [BUILD only]
or [TEST only]. Auth, JWT, crypto, and network packages in production
are highest priority.
If transitive critical findings exist above, favor the same ecosystem.
Examples: [3] or [0] or [7]"""
def choose_neighbor_indexes(
    current_package: str,
    current_version: str,
    cve_count: int,
    current_cvss: float,
    has_critical: bool,
    neighbor_descriptions: str,
    critical_context: str
) -> list[int] by llm(
    model=routing_llm,
    temperature=0,
    max_tokens=16
);

"""Pick ONE direct dependency index from the numbered candidate list.
Return ONLY a JSON array with a single integer, e.g. [3] or [0].
Prioritize auth, jwt, crypto, parse, network, and serialize packages.
No prose, no markdown."""
def select_spawn_root_index(
    candidate_descriptions: str
) -> list[int] by llm(
    model=spawn_llm,
    temperature=0,
    max_tokens=256
);
