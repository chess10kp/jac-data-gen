# walkers/static/impl/pr_comment.impl.jac

import from graph.nodes { PRAnalysisNode }
import from integrations.github { post_pr_comment }

impl PRCommentWriterWalker.post_review with Root entry {
    pr_nodes = [root -->][?:PRAnalysisNode];
    target: PRAnalysisNode | None = None;
    for node in pr_nodes {
        if jid(node) == self.verdict_id {
            target = node;
            break;
        }
    }

    if not target {
        report {"error": f"PRAnalysisNode {self.verdict_id} not found", "status": "failed"};
        return;
    }

    verdict: any = target.verdict;
    if verdict.get("comment_posted", False) {
        report {"status": "already_posted", "comments_posted": 0};
        return;
    }

    try {
        comment_body = self._format_verdict_comment(verdict=verdict);
    } except Exception as e { # jac:ignore[W2052]
        risk = verdict.get("overall_risk", "unknown").upper();
        score = verdict.get("risk_score", 0);
        affected = verdict.get("affected_node_count", 0);
        comment_body = f"""## GhostWatch Analysis

**Overall Risk:** {risk} (score: {score}/100)
**Affected Nodes:** {affected}

**Security Findings:** {len(verdict.get("security_findings", []))}
**Compatibility Issues:** {len(verdict.get("compatibility_issues", []))}
**Blast Radius:** {verdict.get("blast_radius_summary", "N/A")}

**Recommendation:** {verdict.get("recommendation", "Review manually")}

---
*Posted by GhostWatch — System 1 Static Analyzer*""";
    }

    try {
        post_pr_comment(self.pr_url, comment_body);
        target.verdict = {**verdict, "comment_posted": True};
        report {"status": "success", "comments_posted": 1};
    } except Exception as e { # jac:ignore[W2052]
        report {"error": str(e), "status": "failed", "comments_posted": 0};
    }
}
