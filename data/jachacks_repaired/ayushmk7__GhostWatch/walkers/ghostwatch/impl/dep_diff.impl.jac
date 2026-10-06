# walkers/ghostwatch/impl/dep_diff.impl.jac

import from graph.nodes { GhostwatchIncidentNode, FileNode }
import from integrations.github { fetch_file_content }
import from walkers.ghostwatch.sandbox { SandboxExecutorWalker }
import from lib.manifest {
    parse_manifest_deps,
    manifest_delta,
    classify_dependency_risks,
    dedupe_incident_key,
    normalize_package_name,
    apply_package_alias
}
import from time { time }
import from re { findall }

impl DependencyDiffWalker._collect_normalized_imports() -> set[str] {
    names = set();
    for fn in [root -->][?:FileNode] {
        txt = str(fn.content);
        for m in findall(r"(?:^|\n)import\s+([a-zA-Z0-9_]+)", txt) {
            names.add(apply_package_alias(normalize_package_name(m)));
        }
        for m in findall(r"(?:^|\n)from\s+([a-zA-Z0-9_.]+)\s+import", txt) {
            root_pkg = str(m).split(".")[0];
            names.add(apply_package_alias(normalize_package_name(root_pkg)));
        }
    }
    return names;
}

impl DependencyDiffWalker.run with Root entry {
    graph_imports = self._collect_normalized_imports();
    for mp in self.manifest_paths {
        mps = str(mp);
        par = fetch_file_content(self.repo_full_name, mps, self.parent_sha);
        cur = fetch_file_content(self.repo_full_name, mps, self.commit_sha);
        pd = parse_manifest_deps(mps, par);
        cd = parse_manifest_deps(mps, cur);
        delta = manifest_delta(pd, cd);
        added = delta.get("added", {});
        if not added {
            continue;
        }
        risks = classify_dependency_risks(mps, par, cur, added, graph_imports);
        for r in risks {
            nm = str(r.get("name", ""));
            dk = dedupe_incident_key(self.repo_full_name, self.commit_sha, mps, nm);
            ts = str(int(time()));
            matched = False;
            for inc in [root -->][?:GhostwatchIncidentNode] {
                if inc.dedupe_key != dk {
                    continue;
                }
                matched = True;
                if len(inc.behavioral_trace) > 0 {
                    break;
                }
                inc.updated_at = ts;
                inc.risk_level = str(r.get("risk_level", "medium"));
                rc = r.get("rule_codes", []);
                inc.rule_codes = rc;
                inc.dependency_version = str(r.get("version", ""));
                st = str(inc.status);
                if st not in ["malicious", "needs_human_review", "cleared", "sandboxed"] {
                    inc.status = "detected";
                }
                spawn_res = root spawn SandboxExecutorWalker(incident_jid=str(jid(inc)));
                _ = spawn_res;
                break;
            }
            if not matched {
                fresh = (
                    root
                    ++> GhostwatchIncidentNode(
                        dedupe_key=dk,
                        repo_full_name=self.repo_full_name,
                        commit_sha=self.commit_sha,
                        manifest_path=mps,
                        dependency_name=nm,
                        dependency_version=str(r.get("version", "")),
                        status="detected",
                        risk_level=str(r.get("risk_level", "medium")),
                        rule_codes=r.get("rule_codes", []),
                        created_at=ts,
                        updated_at=ts
                    )
                )[0];
                spawn_res2 = root spawn SandboxExecutorWalker(incident_jid=str(jid(fresh)));
                _ = spawn_res2;
            }
        }
    }
    report {"status": "dep_diff_complete"};
}
