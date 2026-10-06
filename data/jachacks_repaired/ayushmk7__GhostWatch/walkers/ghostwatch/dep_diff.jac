# walkers/ghostwatch/dep_diff.jac — Push manifest diff → incidents + sandbox spawn.

walker:pub DependencyDiffWalker {
    has repo_full_name: str;
    has commit_sha: str;
    has parent_sha: str;
    has manifest_paths: list;
    has reports: list = [];

    can run with Root entry;

    def _collect_normalized_imports() -> set[str];
}
