# walkers/static/pr_comment.jac
# PRCommentWriterWalker: posts a single review comment to GitHub PR on Approve.
# Idempotent — checks if comment already posted before writing.
# Implementation in impl/pr_comment.impl.jac

walker:pub PRCommentWriterWalker {
    has pr_url: str;
    has verdict_id: str;
    has reports: list[dict] = [];

    can post_review with Root entry;

    def _format_verdict_comment(verdict: dict) -> str by llm;
}

sem PRCommentWriterWalker._format_verdict_comment = "Format the verdict dict as a clear, concise GitHub PR review comment in Markdown. Include overall risk, key security findings, compatibility issues, blast radius, and recommendation."; # jac:ignore[W2001]
