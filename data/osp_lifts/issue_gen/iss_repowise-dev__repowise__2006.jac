# PROGRAM: repowise-dev/repowise#2006

node Workspace {
    has name: str;
}

node ContractLink {
    has provider_repo: str;
    has provider_path: str;
    has consumer_repo: str;
    has confidence: str;
}

node TestTarget {
    has repo: str;
    has path: str;
    has basis: str;
    has via: str;
    has source_file: str;
}

edge Contains {}
edge Targets {}
edge Returns {}

obj WorkspaceIndex {
    has graph_root: Workspace;
}

walker ImpactWalker {
    has changed_repo: str;
    has changed_path: str;
    has active_confidence: str = "";
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];

    can scan_workspace with Workspace entry {
        claimed_map: dict[str, bool] = self.claimed;
        if here.cid in claimed_map {
            skip;
        }
        claimed_map[here.cid] = True;
        print("workspace scan " + self.changed_repo + ":" + self.changed_path);
        for link_node in [here ->:Contains:->][?:ContractLink] {
            visit :0: [link_node];
        }
    }

    can scan_link with ContractLink entry {
        claimed_map: dict[str, bool] = self.claimed;
        if here.cid in claimed_map {
            skip;
        }
        claimed_map[here.cid] = True;
        if here.provider_repo == self.changed_repo
            and here.provider_path == self.changed_path {
            self.active_confidence = here.confidence;
            for test_node in [here ->:Targets:->][?:TestTarget] {
                visit :0: [test_node];
            }
        }
    }

    can scan_test with TestTarget entry {
        claimed_map: dict[str, bool] = self.claimed;
        if here.cid in claimed_map {
            skip;
        }
        claimed_map[here.cid] = True;
        hit: str = here.repo + ":" + here.path + "|" + here.basis + "|"
            + here.via + "|" + self.active_confidence + "|"
            + here.source_file;
        if hit not in self.found {
            self.found.append(hit);
            print(hit);
        }
        for parent_node in [here ->:Returns:->][?:Workspace] {
            visit :0: [parent_node];
        }
    }
}

def build_workspace(
    links: list[dict[str, str]],
    tests: list[dict[str, str]]
) -> WorkspaceIndex {
    graph_root = Workspace(name="workspace");
    test_map: dict[str, TestTarget] = {};

    for test_data in tests {
        test_node = TestTarget(
            repo=test_data["repo"],
            path=test_data["path"],
            basis=test_data["basis"],
            via=test_data["via"],
            source_file=test_data["source_file"]
        );
        test_key: str = test_data["repo"] + ":" + test_data["path"]
            + "|" + test_data["basis"] + "|" + test_data["via"]
            + "|" + test_data["source_file"];
        test_map[test_key] = test_node;
        test_node +>:Returns:+> graph_root;
    }

    for link_data in links {
        link_node = ContractLink(
            provider_repo=link_data["provider_repo"],
            provider_path=link_data["provider_path"],
            consumer_repo=link_data["consumer_repo"],
            confidence=link_data["confidence"]
        );
        graph_root +>:Contains:+> link_node;
        for test_key in test_map {
            test_node: TestTarget = test_map[test_key];
            if link_node.consumer_repo == test_node.repo {
                link_node +>:Targets:+> test_node;
            }
        }
    }

    return WorkspaceIndex(graph_root=graph_root);
}

def get_workspace_test_impact(
    index: WorkspaceIndex,
    changed_files: list[dict[str, str]]
) -> list[str] {
    results: list[str] = [];
    graph_root: Workspace = index.graph_root;

    for changed in changed_files {
        repo_name: str = changed["repo"];
        path_name: str = changed["path"];
        w = graph_root spawn ImpactWalker(
            changed_repo=repo_name,
            changed_path=path_name,
            claimed={},
            found=[]
        );
        for hit in w.found {
            if hit not in results {
                results.append(hit);
            }
        }
    }

    return sorted(results);
}
