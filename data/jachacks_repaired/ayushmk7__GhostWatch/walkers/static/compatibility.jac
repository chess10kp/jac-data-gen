# walkers/static/compatibility.jac

import from graph.nodes { FileNode }
import from objects.verdict { CompatibilityIssue }

walker CompatibilityCheckerWalker {
    has pr_diff: str = "";
    has changed_apis: list[str] = [];
    has allowed_nodes: set[str] = set();
    has findings: list[CompatibilityIssue] = [];
    has traversal_path: list[str] = [];

    can check_api_surface with FileNode entry;

    def check_compatibility(file_content: str, changed_apis: list[str], file_path: str) -> list[CompatibilityIssue] by llm;

    def _uses_changed_api(content: str, changed_apis: list[str]) -> bool by llm;
}

sem CompatibilityCheckerWalker.check_compatibility = "Analyze whether this file calls any of the changed APIs in a way that would break due to the PR changes. Return a list of compatibility issues found."; # jac:ignore[W2001]
sem CompatibilityCheckerWalker._uses_changed_api = "Return True if the file content uses or imports any of the named APIs in changed_apis list, False otherwise."; # jac:ignore[W2001]
