"""EffortlessMetrics/perl-lsp-swarm#7648 -- Moose canonical facts."""

from __future__ import annotations

from collections import deque

class MooseRegistry:
    def __init__(self) -> None:
        self.attrs: dict[str, dict] = {}
        self.provided: dict[str, str] = {}
        self.hooks: dict[str, list[str]] = {}
        self.constraints: dict[str, str] = {}
        self.parents: dict[str, str | None] = {}
        self.children: dict[str, list[str]] = {}

def make_registry() -> MooseRegistry:
    return MooseRegistry()

def register_moose_attribute(reg: MooseRegistry, pkg: str, attr: str, is_mode: str | None, opts: dict) -> None:
    if pkg not in reg.children:
        reg.children[pkg] = []
        reg.parents[pkg] = None
    key = f"{pkg}::{attr}"
    if key in reg.attrs:
        raise ValueError("duplicate")
    # Moose: ro, rw, bare, or None (no accessor); lazy separate
    if is_mode is not None and is_mode not in ("ro", "rw", "bare"):
        raise ValueError("invalid moose is_mode")
    reg.attrs[key] = {"pkg": pkg, "attr": attr, "is": is_mode, "opts": dict(opts)}
    # provided members
    if is_mode == "ro":
        reg.provided[attr] = key
    elif is_mode == "rw":
        reg.provided[attr] = key
    elif is_mode == "bare":
        pass  # no accessor
    elif is_mode is None:
        pass
    # lazy_build adds builder hook vs lazy flag
    if opts.get("lazy_build"):
        reg.hooks[key] = [f"_build_{attr}"]
    else:
        hooks = []
        if "builder" in opts:
            hooks.append(opts["builder"])
        if "trigger" in opts:
            hooks.append(opts["trigger"])
        if hooks:
            reg.hooks[key] = hooks
    # constraint
    if "isa" in opts:
        isa = opts["isa"]
        if isinstance(isa, str) and isa:
            reg.constraints[key] = isa
        else:
            reg.constraints[key] = "dynamic"

def add_extends(reg: MooseRegistry, child: str, parent: str) -> None:
    for n in (child, parent):
        if n not in reg.children:
            reg.children[n] = []
            reg.parents[n] = None
    reg.parents[child] = parent
    reg.children[parent].append(child)

def provided_members(reg: MooseRegistry, pkg: str) -> list[str]:
    out: set[str] = set()
    q: deque[str] = deque([pkg])
    seen: set[str] = set()
    while q:
        cur = q.popleft()
        if cur in seen:
            continue
        seen.add(cur)
        for k, v in reg.provided.items():
            if v.startswith(cur + "::") and k not in out:
                out.add(k)
        p = reg.parents.get(cur)
        if p:
            q.append(p)
    return sorted(out)

def referenced_hooks(reg: MooseRegistry, key: str) -> list[str]:
    return sorted(reg.hooks.get(key, []))

def constraint_for(reg: MooseRegistry, key: str) -> str | None:
    return reg.constraints.get(key)

def ancestor_chain(reg: MooseRegistry, pkg: str) -> list[str]:
    chain: list[str] = []
    cur: str | None = pkg
    seen: set[str] = set()
    while cur and cur not in seen:
        chain.append(cur)
        seen.add(cur)
        cur = reg.parents.get(cur)
    return chain
