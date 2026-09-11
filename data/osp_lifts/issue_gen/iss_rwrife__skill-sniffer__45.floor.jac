"""rwrife/skill-sniffer#45 — Follow bundled refs with depth-capped recursive walk.

Skills reference bundled scripts; --follow-refs resolves local paths via an
adjacency dict and recursive descent with visited cycle guard and depth cap.
"""
import from __future__ { annotations }
class SkillBundle {
    def init(self: SkillBundle) -> None {
        self.files: set[str] = `set();
        self.refs: dict[(str, list[str])] = {};
    }
}
def load_bundle(files: list[str], ref_edges: list[tuple[(str, str)]]) -> SkillBundle {
    bundle = SkillBundle();
    for path in files {
        bundle.files.add(path);
        bundle.refs.setdefault(path, []);
    }
    for (src, dst) in ref_edges {
        if ((src in bundle.files) and (dst in bundle.files)) {
            bundle.refs.setdefault(src, []).append(dst);
            bundle.refs.setdefault(dst, bundle.refs.get(dst, []));
        }
    }
    return bundle;
}
def follow_refs(bundle: SkillBundle, start: str, max_depth: int) -> list[str] {
    if (start not in bundle.files) {
        return [];
    }
    seen: set[str] = `set();
    out: list[str] = [];
    def walk(`node: str, depth: int) -> None {
        if ((depth > max_depth) or (`node in seen)) {
            return;
        }
        seen.add(`node);
        out.append(`node);
        for nxt in bundle.refs.get(`node, []) {
            walk(nxt, (depth + 1));
        }
    }
    walk(start, 0);
    return sorted(out);
}

