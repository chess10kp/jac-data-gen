# walkers/static/orchestrator.jac — OrchestratorWalker declaration.
# Dispatches three specialist walkers in parallel via flow/wait wrapper functions.

import from graph.nodes { FileNode, PRAnalysisNode }
import from objects.verdict { VerdictObject }
import from walkers.static.security { SecurityAuditorWalker }
import from walkers.static.compatibility { CompatibilityCheckerWalker }
import from walkers.static.blast_radius { BlastRadiusMapperWalker }

walker:pub OrchestratorWalker {
    has pr_url: str;
    has verdict: dict[str, any] = {};

    can orchestrate with Root entry;

    def _run_security(start_node: FileNode, allowed_nodes: set[str], diff: str) -> dict[str, any];
    def _run_compat(start_node: FileNode, allowed_nodes: set[str], changed_apis: list[str], diff: str) -> dict[str, any];
    def _run_blast(start_node: FileNode, changed_paths: list[str]) -> dict[str, any];
    def _get_subgraph_root() -> FileNode | None;
    def _build_allowed_nodes(changed_files: list[str]) -> set[str];
    def _derive_risk_label(verdict: dict[str, any]) -> str;
    def _discord_summary(pr_url: str, verdict: dict[str, any]) -> str;

    def _merge_findings(security: any, compat: any, blast: any, pr_url: str) -> VerdictObject by llm;
}

sem OrchestratorWalker._merge_findings = "Synthesize security findings, compatibility issues, and blast radius data into a single VerdictObject representing the overall risk of this PR."; # jac:ignore[W2001]
