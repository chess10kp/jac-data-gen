"""Recursive function to annotate each node with the count of all
    of it's descendants, as well as the count of all sibling comments plus
    their children, made after each node.
    """
def annotate_counts(`node: Any) -> object {
    `node['reply_count'] = 0;
    if not `node['replies'] {
        return 1;
    } else {
        for r in `node['replies'] {
            `node['reply_count'] += annotate_counts(r);
        }
        after_count = 0;
        for r in reversed(`node['replies']) {
            r['after_count'] = after_count;
            after_count += r['reply_count'] + 1;
        }
        return (`node['reply_count'] + 1);
    }
}