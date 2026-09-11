"""EffortlessMetrics/perl-lsp-swarm#4908 -- Moo registry-backed facts."""

from __future__ import annotations

from collections import deque

class MooRegistry:
    def __init__(self) -> None:
        self.attrs: dict[str, dict] = {}  # attr -> meta
        self.provided: dict[str, str] = {}  # generated_name -> attr
        self.hooks: dict[str, list[str]] = {}  # attr -> [builder, trigger]
        self.parents: dict[str, str | None] = {}
        self.children: dict[str, list[str]] = {}

def make_registry() -> MooRegistry:
    return MooRegistry()

def register_attribute(reg: MooRegistry, pkg: str, attr: str, is_mode: str, opts: dict) -> None:
    if pkg not in reg.children:
        reg.children[pkg] = []
        reg.parents[pkg] = None
    if f"{pkg}::{attr}" in reg.attrs:
        raise ValueError("duplicate attribute")
    # validate is_mode via issue #8935: ro/rw/rwp/lazy only; bare not admitted for Moo
    if is_mode not in ("ro", "rw", "rwp", "lazy"):
        raise ValueError("non-exact is mode")
    reg.attrs[f"{pkg}::{attr}"] = {"pkg": pkg, "attr": attr, "is": is_mode, "opts": dict(opts)}
    # provided members
    if is_mode == "ro":
        reg.provided[attr] = f"{pkg}::{attr}"
    elif is_mode == "rw":
        reg.provided[attr] = f"{pkg}::{attr}"
    elif is_mode == "rwp":
        reg.provided[attr] = f"{pkg}::{attr}"
        reg.provided[f"_set_{attr}"] = f"{pkg}::{attr}"
    elif is_mode == "lazy":
        reg.provided[attr] = f"{pkg}::{attr}"
    # hooks
    hooks = []
    if "builder" in opts:
        hooks.append(opts["builder"])
    if "trigger" in opts:
        hooks.append(opts["trigger"])
    reg.hooks[f"{pkg}::{attr}"] = hooks

def add_extends(reg: MooRegistry, child: str, parent: str) -> None:
    if child not in reg.children:
        reg.children[child] = []
    if parent not in reg.children:
        reg.children[parent] = []
    reg.parents[child] = parent
    reg.children[parent].append(child)

def provided_members(reg: MooRegistry, pkg: str) -> list[str]:
    # BFS up inheritance chain to collect provided
    out: list[str] = []
    seen: set[str] = set()
    q: deque[str] = deque([pkg])
    visited: set[str] = set()
    while q:
        cur = q.popleft()
        if cur in visited:
            continue
        visited.add(cur)
        for k, v in reg.provided.items():
            owner = v.split("::")[0]
            if owner == cur and k not in seen:
                out.append(k)
                seen.add(k)
        parent = reg.parents.get(cur)
        if parent:
            q.append(parent)
    return sorted(out)

def referenced_hooks(reg: MooRegistry, attr_key: str) -> list[str]:
    return sorted(reg.hooks.get(attr_key, []))

def ancestor_chain(reg: MooRegistry, pkg: str) -> list[str]:
    chain: list[str] = []
    cur = pkg
    seen: set[str] = set()
    while cur and cur not in seen:
        chain.append(cur)
        seen.add(cur)
        cur = reg.parents.get(cur)  # type: ignore
    return chain
