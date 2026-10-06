# walkers/static/impl/compatibility.impl.jac

import from graph.nodes { FileNode }

impl CompatibilityCheckerWalker.check_api_surface with FileNode entry {
    if self.allowed_nodes and jid(here) not in self.allowed_nodes {
        visit [-->][?:FileNode];  # Keep traversing even for non-allowed nodes
        return;
    }
    self.traversal_path.append(jid(here));
    try {
        if self._uses_changed_api(content=here.content, changed_apis=self.changed_apis) {
            new_findings = self.check_compatibility(
                file_content=here.content,
                changed_apis=self.changed_apis,
                file_path=here.path
            );
            self.findings = self.findings + new_findings;
        }
    } except Exception as e { # jac:ignore[W2052]
        print(f"CompatibilityChecker LLM call failed for {here.path}: {e}");
    }
    visit [-->][?:FileNode];
    report {
        "findings": self.findings,
        "traversal_path": self.traversal_path
    };
}
