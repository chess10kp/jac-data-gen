# walkers/ghostwatch/gap_analysis.jac — Post-merge gap analysis.

walker:pub GapAnalysisWalker {
    has repo_full_name: str;
    has merge_commit_sha: str;
    has reports: list = [];

    can run with Root entry;

    def _word_suggestion(path: str, gap_kind: str) -> dict;
}
