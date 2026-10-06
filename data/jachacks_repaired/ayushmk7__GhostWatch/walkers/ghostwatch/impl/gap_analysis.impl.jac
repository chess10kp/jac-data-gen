# walkers/ghostwatch/impl/gap_analysis.impl.jac

import from graph.nodes { FileNode, TestNode, DocumentationNode, GapAnalysisNode }
import from lib.manifest { rank_gap_candidates, impl_likely_has_conventional_test }
import from integrations.discord { notify_discord_gap_digest }
import from time { time }

impl GapAnalysisWalker._word_suggestion(path: str, gap_kind: str) -> dict {
    return {
        "title": f"Improve {path}",
        "description": f"Address gap ({gap_kind}) for {path}",
        "difficulty": "intermediate",
        "file_path": path,
        "suggestion_type": gap_kind
    };
}

impl GapAnalysisWalker.run with Root entry {
    paths = [];
    test_paths = set();
    doc_paths = set();
    for fn in [root -->][?:FileNode] {
        paths.append(fn.path);
    }
    for tn in [root -->][?:TestNode] {
        test_paths.add(tn.path);
    }
    for dn in [root -->][?:DocumentationNode] {
        doc_paths.add(dn.path);
    }
    core_prefixes = ["graph/", "walkers/", "lib/", "integrations/", "frontend/"];
    ranked = rank_gap_candidates(paths, test_paths, doc_paths, core_prefixes);
    suggestions = [];
    max_n = 5;
    for item in ranked {
        if len(suggestions) >= max_n {
            break;
        }
        p = str(item.get("path", ""));
        if not p {
            continue;
        }
        cov_t = impl_likely_has_conventional_test(p, test_paths);
        cov_d = (not p.endswith(".jac")) or (p in doc_paths);
        ph = "placeholder" in str(p).lower() or "todo" in str(p).lower();
        if cov_t and cov_d and not ph {
            continue;
        }
        gap_kind = "missing_tests";
        if ph {
            gap_kind = "incomplete_feature";
        } elif not cov_t {
            gap_kind = "missing_tests";
        } elif p.endswith(".jac") and p not in doc_paths {
            gap_kind = "missing_docs";
        }
        try {
            sug = self._word_suggestion(path=p, gap_kind=gap_kind);
        } except Exception {
            sug = {
                "title": f"Improve {p}",
                "description": f"Address gap ({gap_kind}) for {p}",
                "difficulty": "intermediate",
                "file_path": p,
                "suggestion_type": gap_kind
            };
        }
        suggestions.append(sug);
    }
    if len(suggestions) < 3 {
        for item in ranked {
            if len(suggestions) >= 3 {
                break;
            }
            p = str(item.get("path", ""));
            if not p {
                continue;
            }
            dup_path = False;
            for s in suggestions {
                if str(s.get("file_path", "")) == p {
                    dup_path = True;
                    break;
                }
            }
            if dup_path {
                continue;
            }
            suggestions.append(
                {
                    "title": f"Cover {p}",
                    "description": "Add tests or documentation as appropriate.",
                    "difficulty": "good-first-issue",
                    "file_path": p,
                    "suggestion_type": "missing_tests"
                }
            );
        }
    }
    ts = str(int(time()));
    _ = (root ++> GapAnalysisNode(merge_commit_sha=self.merge_commit_sha, suggestions=suggestions, created_at=ts))[0];
    notify_discord_gap_digest({"merge_commit_sha": self.merge_commit_sha, "suggestions": suggestions});
    report {"suggestions": len(suggestions)};
}
