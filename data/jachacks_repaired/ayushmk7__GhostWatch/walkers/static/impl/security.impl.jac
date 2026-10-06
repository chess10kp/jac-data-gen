# walkers/static/impl/security.impl.jac

import from graph.nodes { FileNode }

impl SecurityAuditorWalker.analyze with FileNode entry {
    if self.allowed_nodes and jid(here) not in self.allowed_nodes {
        visit [-->][?:FileNode];  # Keep traversing even for non-allowed nodes
        return;
    }
    if here.is_test {
        visit [-->][?:FileNode];
        return;
    }
    self.traversal_path.append(jid(here));
    try {
        new_findings = self.audit_file(
            content=here.content,
            path=here.path,
            pr_context=self.pr_context
        );
        self.findings = self.findings + new_findings;
    } except Exception as e { # jac:ignore[W2052]
        print(f"SecurityAuditor LLM call failed for {here.path}: {e}");
    }
    visit [-->][?:FileNode];
    report {
        "findings": self.findings,
        "traversal_path": self.traversal_path
    };
}
