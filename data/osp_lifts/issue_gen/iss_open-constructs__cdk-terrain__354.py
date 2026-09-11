"""Reify construct-level dependencies into resource-level depends_on.

CDKTN inherits the ``constructs`` library's ``node.addDependency()`` API but
nothing in the framework ever reads ``node.dependencies``: a dependency
declared on an L2/L3 construct is silently dropped at synth time and never
becomes ``depends_on`` in the generated Terraform. Abstraction authors must
manually plumb ``dependsOn`` arrays down to every leaf resource themselves.

The reification pass below gives ``synth_dependencies`` the AWS CDK
semantics: a dependency declared between two constructs means every leaf
resource under the source construct depends on every leaf resource under
the target construct. It keeps the construct tree as a children map keyed
by construct path, walks it with an explicit stack and a seen set to
collect the leaves beneath each endpoint, and unions the cross product per
declaration. Self pairs are skipped so a dependency on an ancestor
construct never makes a resource depend on itself. Unknown construct
paths raise ``KeyError`` -- a dependency on a construct that does not
exist must fail synth, not pass silently.
Ref: open-constructs/cdk-terrain#354
"""


def leaves_under(tree, path):
    """Every leaf resource path beneath construct ``path``, sorted.

    ``tree`` maps each construct path (e.g. ``"stack/api"``) to the list of
    its child construct paths; a construct with no children is a leaf
    resource. The sweep is a manual stack walk over the children map, with
    a seen set guarding against diamond-shaped child lists.
    """
    stack = [path]
    seen = set()
    found = []
    while stack:
        cur = stack.pop()
        if cur in seen:
            continue
        seen.add(cur)
        kids = tree[cur]  # unknown construct: KeyError, same as synth
        if kids:
            stack.extend(kids)
        else:
            found.append(cur)
    return sorted(found)


def synth_dependencies(tree, deps):
    """Reify construct-level dependencies into leaf-to-leaf depends_on.

    ``deps`` lists ``(source_construct, target_construct)`` path pairs
    declared through ``node.addDependency``. Every leaf under a source
    construct gains a dependency on every leaf under the target construct
    (self pairs skipped), re-walking the tree per declaration. Returns
    ``{leaf_path: sorted depended-on leaf paths}`` holding only leaves
    that gained at least one dependency.
    """
    out = {}
    for src, dst in deps:
        src_leaves = leaves_under(tree, src)
        dst_leaves = leaves_under(tree, dst)
        for s in src_leaves:
            for d in dst_leaves:
                if s != d:
                    out.setdefault(s, set()).add(d)
    return {k: sorted(v) for k, v in out.items()}
