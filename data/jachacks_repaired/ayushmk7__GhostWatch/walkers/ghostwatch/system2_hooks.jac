# walkers/ghostwatch/system2_hooks.jac — Manual demo triggers + escalation tick.

walker:pub System2PushTriggerWalker {
    has repo_full_name: str;
    has commit_sha: str;
    has parent_sha: str;
    has manifest_paths: list;
    has reports: list = [];

    can run with Root entry;
}

walker:pub System2MergeTriggerWalker {
    has repo_full_name: str;
    has merge_commit_sha: str;
    has reports: list = [];

    can run with Root entry;
}

walker:pub System2EscalationTickWalker {
    has reports: list = [];

    can run with Root entry;
}
