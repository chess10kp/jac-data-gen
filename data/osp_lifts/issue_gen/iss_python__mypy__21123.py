"""Bounded alias expansion for infinitely growing type aliases.

mypy expands type aliases by recursive substitution: the alias table maps
each alias name to a list of parts, and any part that is itself an alias
key is substituted again. An alias family that grows without bound
(``A = list[A]`` fed through ``Concatenate``) drives that recursion past
Python's limit and crashes the build with ``RecursionError`` -- the
internal error of the report. The remediation keeps both shapes: ``expand``
still fully expands acyclic tables (and still raises RecursionError on a
cyclic table, exactly as the unfixed mypy does), while ``expand_bounded``
walks with a depth cap and returns the partial expansion plus a
``truncated`` flag instead of crashing.
Ref: python/mypy#21123
"""

MAX_EXPANSION_DEPTH = 8


def expand(name, aliases):
    """Fully expanded terminal parts of ``name``, sorted and deduped.

    A part that is not an alias key is a terminal and is collected; an
    alias part is substituted recursively. Raises RecursionError when the
    alias table is cyclic (the pre-fix crash, preserved on purpose).
    """
    out = set()

    def walk(cur):
        if cur not in aliases:
            out.add(cur)
            return
        for part in aliases[cur]:
            walk(part)

    walk(name)
    return sorted(out)


def expand_bounded(name, aliases, max_depth=MAX_EXPANSION_DEPTH):
    """Depth-capped expansion: ``{"parts": [...], "truncated": bool}``.

    Same substitution walk, but the recursion stops once an alias sits at
    ``max_depth`` and still needs expanding; the terminals reached before
    the cap are returned with ``truncated`` set, so cyclic tables
    terminate instead of crashing the build.
    """
    out = set()
    state = {"truncated": False}

    def walk(cur, d: int):
        if cur not in aliases:
            out.add(cur)
            return
        if d >= max_depth:
            state["truncated"] = True
            return
        for part in aliases[cur]:
            walk(part, d + 1)

    walk(name, 0)
    return {"parts": sorted(out), "truncated": state["truncated"]}
