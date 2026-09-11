"""cue-lang/cue#2555 — CUE package evaluator with file-order-sensitive reference closure."""
from __future__ import annotations

from collections import deque


class CueFile:
    def __init__(
        self,
        fname: str,
        deployment_comp: bool = False,
        oauth_comp: bool = False,
        template: bool = False,
        instances: dict[str, str] | None = None,
    ) -> None:
        self.fname = fname
        self.deployment_comp = deployment_comp
        self.oauth_comp = oauth_comp
        self.template = template
        self.instances = instances if instances is not None else {}


class PackageGraph:
    def __init__(self) -> None:
        self.files: dict[str, dict[str, object]] = {}
        self.refs: dict[str, list[str]] = {}
        self.file_nodes: dict[str, CueFile] = {}


def load_package(
    files: list[tuple[str, dict[str, object]]],
    refs: list[tuple[str, str]] | None = None,
) -> PackageGraph:
    pkg = PackageGraph()
    for fname, spec in files:
        pkg.files[fname] = dict(spec)
        pkg.refs.setdefault(fname, [])
        s = dict(spec)
        inst_raw = s.get("instances", {})
        inst: dict[str, str] = {}
        if inst_raw is not None:
            for k, v in dict(inst_raw).items():
                inst[str(k)] = str(v)
        pkg.file_nodes[fname] = CueFile(
            fname=fname,
            deployment_comp=bool(s.get("deployment_comp", False)),
            oauth_comp=bool(s.get("oauth_comp", False)),
            template=bool(s.get("template", False)),
            instances=inst,
        )
    for src, dst in refs or []:
        if src in pkg.files:
            pkg.refs.setdefault(src, []).append(dst)
    return pkg


def resolve_load_order(pkg: PackageGraph, order: list[str] | None = None) -> list[str]:
    if order is not None:
        out: list[str] = []
        for f in order:
            if f in pkg.files:
                out.append(f)
        return out
    return sorted(pkg.files.keys())


def transitive_field_refs(pkg: PackageGraph, file_id: str) -> list[str]:
    if file_id not in pkg.files or pkg.file_nodes.get(file_id, None) is None:
        return []
    claimed: dict[str, bool] = {}
    found: list[str] = []
    q: deque[str] = deque(pkg.refs.get(file_id, []))
    while q:
        cur = q.popleft()
        if cur in claimed:
            continue
        claimed[cur] = True
        if cur != file_id and cur in pkg.files:
            found.append(cur)
        if cur in pkg.files:
            for nxt in pkg.refs.get(cur, []):
                if nxt not in claimed:
                    q.append(nxt)
    return sorted(found)


def cyclic_reference_fields(pkg: PackageGraph) -> list[str]:
    visited: dict[str, bool] = {}
    cycles: list[str] = []

    def dfs(node: str, stack: dict[str, bool]) -> None:
        if node in visited:
            if node in stack:
                cycles.append(node)
            return
        visited[node] = True
        stack[node] = True
        for nxt in sorted(pkg.refs.get(node, [])):
            if nxt in pkg.files:
                dfs(nxt, stack)
        del stack[node]

    for fn in sorted(pkg.files.keys()):
        if fn not in visited:
            dfs(fn, {})
    uniq: dict[str, bool] = {}
    for c in cycles:
        uniq[c] = True
    return sorted(uniq.keys())


def export_package(
    pkg: PackageGraph,
    load_order: list[str] | None = None,
) -> dict[str, object] | str:
    order = resolve_load_order(pkg, load_order)
    deployment: dict[str, str] = {}
    oauth: dict[str, str] = {}
    deployment_comprehension_ran = False
    deployment_at_comprehension: dict[str, bool] = {}
    for fname in order:
        spec = pkg.files[fname]
        if spec.get("deployment_comp", False):
            deployment_comprehension_ran = True
            deployment_at_comprehension = {}
            for k in deployment.keys():
                deployment_at_comprehension[k] = True
        inst_raw = spec.get("instances", {})
        inst_dict: dict[str, object] = dict(inst_raw) if inst_raw is not None else {}
        for iid, iname in sorted(inst_dict.items()):
            oauth[str(iid)] = str(iname)
        if spec.get("oauth_comp", False):
            oauth_items: list[tuple[str, str]] = []
            for iid, iname in oauth.items():
                oauth_items.append((iid, iname))
            for iid, iname in sorted(oauth_items):
                dep_key = f"{iname}-proxy"
                if deployment_comprehension_ran and dep_key not in deployment_at_comprehension:
                    return (
                        f'deployment: field "{dep_key}" not allowed by earlier '
                        "comprehension or reference cycle"
                    )
                deployment[dep_key] = "proxy"
    dep_out: dict[str, str] = {}
    for k, v in sorted(deployment.items()):
        dep_out[k] = v
    oauth_out: dict[str, str] = {}
    for k, v in sorted(oauth.items()):
        oauth_out[k] = v
    return {"deployment": dep_out, "oAuthProxy": oauth_out}


def kube_reproducer(rename_z_to_a: bool = False) -> PackageGraph:
    zfile = "a.cue" if rename_z_to_a else "z.cue"
    return load_package(
        [
            (zfile, {"deployment_comp": True}),
            ("b.cue", {"oauth_comp": True, "template": True}),
            ("c.cue", {"instances": {"prometheus": "prometheus"}}),
        ],
        [
            ("b.cue", "c.cue"),
            ("b.cue", zfile),
            (zfile, "b.cue"),
        ],
    )
