#!/usr/bin/env python3
"""Static guard: every subprocess spawn that runs `jac` must pin a sandbox cwd.

jac and the code it executes write relative to CWD — `.pytest_cache/`, `.jac/`
caches, `save_file()` outputs, bytecode dumps. A jac spawn that inherits the
caller's cwd is how the repo root got littered in 2026-08/09.

Rule: any `subprocess.{run,Popen,check_output,check_call,call}` whose command
is jac must pass `cwd=...`, or carry a `# sandbox-exempt` marker on the call
(proven-safe cases like `jac --version`). The command is argv[0]: a literal
"jac", a name like `JAC`/`jac_bin`, a `.JAC` attribute, or a variable that
resolves (one hop, within scope) to a list whose first element is one of
those. Variables that don't resolve are conservatively treated as jac.
Arguments beyond argv[0] are ignored: `pkill ... jac` must not match.

Run: python3 scripts/ops/check_jac_cwd.py   (exit 1 on violations)
Also enforced as scripts/eval/test_jac_spawn_hygiene.py in the pytest suite.
"""
from __future__ import annotations

import ast
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
ROOTS = [REPO / "scripts"]
SPAWN_FUNCS = {"run", "Popen", "check_output", "check_call", "call"}
MARKER = "sandbox-exempt"
SCOPE_NODES = (ast.FunctionDef, ast.AsyncFunctionDef, ast.Lambda, ast.ClassDef)


def argv0_is_jac(expr: ast.expr, assigns: dict[str, ast.expr], depth: int = 0) -> bool:
    if depth > 3:
        return True  # unresolved chain — be conservative
    if isinstance(expr, ast.Constant) and isinstance(expr.value, str):
        return expr.value == "jac" or expr.value.startswith("jac ")
    if isinstance(expr, ast.Name):
        if expr.id in assigns:
            return argv0_is_jac(assigns[expr.id], assigns, depth + 1)
        return True  # unresolved variable command — could be jac at runtime
    if isinstance(expr, ast.Attribute):
        return expr.attr in {"jac", "JAC"}
    return False  # computed path (str(REPO / ...), sys.executable, ...) — not jac


def is_jac_spawn(call: ast.Call, assigns: dict[str, ast.expr]) -> bool:
    if not call.args:
        return False
    c = call.args[0]
    if isinstance(c, (ast.List, ast.Tuple)) and c.elts:
        c = c.elts[0]
    if isinstance(c, ast.Name) and c.id in assigns:
        return argv0_is_jac(assigns[c.id], assigns)
    return argv0_is_jac(c, assigns)


def scan(tree: ast.AST, rel: str, lines: list[str], violations: list[str]) -> int:
    checked = 0

    def visit(node: ast.AST, assigns: dict[str, ast.expr]) -> None:
        nonlocal checked
        for child in ast.iter_child_nodes(node):
            if isinstance(child, SCOPE_NODES):
                visit(child, {})  # fresh scope for nested defs
                continue
            if (
                isinstance(child, ast.Assign)
                and isinstance(child.targets[0], ast.Name)
                and isinstance(child.value, (ast.List, ast.Tuple))
                and child.value.elts
            ):
                assigns[child.targets[0].id] = child.value.elts[0]
            if (
                isinstance(child, ast.Call)
                and isinstance(child.func, ast.Attribute)
                and isinstance(child.func.value, ast.Name)
                and child.func.value.id == "subprocess"
                and child.func.attr in SPAWN_FUNCS
                and is_jac_spawn(child, assigns)
            ):
                checked += 1
                seg = "\n".join(lines[child.lineno - 1 : child.end_lineno])
                if any(kw.arg == "cwd" for kw in child.keywords) or MARKER in seg:
                    continue
                violations.append(
                    f"{rel}:{child.lineno}: jac spawn without cwd "
                    f"(add cwd=<sandbox> or # {MARKER})"
                )
            visit(child, assigns)

    visit(tree, {})
    return checked


def main() -> int:
    violations: list[str] = []
    checked = 0
    for root in ROOTS:
        for path in sorted(root.rglob("*.py")):
            if path.name == Path(__file__).name or "__pycache__" in path.parts:
                continue
            src = path.read_text()
            try:
                tree = ast.parse(src)
            except SyntaxError as e:
                violations.append(f"{path.relative_to(REPO)}: SyntaxError: {e}")
                continue
            checked += scan(tree, str(path.relative_to(REPO)), src.splitlines(), violations)

    print(f"checked {checked} jac spawn site(s)")
    if violations:
        print(f"\nUNSANDBOXED JAC SPAWNS ({len(violations)}):")
        for v in violations:
            print(f"  {v}")
        return 1
    print("OK: all jac spawns pin a sandbox cwd")
    return 0


if __name__ == "__main__":
    sys.exit(main())
