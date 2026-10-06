# walkers/static/security.jac

import from graph.nodes { FileNode }
import from objects.verdict { SecurityFinding }

walker SecurityAuditorWalker {
    has pr_context: str = "";
    has allowed_nodes: set[str] = set();
    has findings: list[SecurityFinding] = [];
    has traversal_path: list[str] = [];

    can analyze with FileNode entry;

    def audit_file(content: str, path: str, pr_context: str) -> list[SecurityFinding] by llm;
}

sem SecurityAuditorWalker.audit_file = "Analyze the file content for security vulnerabilities introduced or exposed by this PR diff. Consider injection, auth bypass, secrets exposure, and unsafe operations."; # jac:ignore[W2001]
