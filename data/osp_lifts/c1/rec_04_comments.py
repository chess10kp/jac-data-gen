"""Comment thread lineage.

Comments link to their parents through ``parent`` / ``replies``
pointers. Thread paths recursively ascend to the original post (OP);
reply volume is measured by recursive descent.
"""


class Comment:
    def __init__(self, author, body):
        self.author = author
        self.body = body
        self.parent = None       # Comment | None (OP)
        self.replies = []        # list[Comment]


def post(parent, author, body):
    """Create a reply under ``parent`` (None for an OP) and return it."""
    c = Comment(author, body)
    if parent is not None:
        c.parent = parent
        parent.replies.append(c)
    return c


def thread_path(c):
    """Authors from the OP down to ``c``, inclusive; OP first."""
    if c.parent is None:
        return [c.author]
    return thread_path(c.parent) + [c.author]


def reply_count(c):
    """Number of replies at or below ``c``, excluding ``c`` itself."""
    total = len(c.replies)
    for r in c.replies:
        total += reply_count(r)
    return total


def op_author(c):
    """Author of the thread-starting comment above ``c``."""
    cur = c
    while cur.parent is not None:
        cur = cur.parent
    return cur.author


def deepest_reply(c):
    """Length of the longest reply chain below ``c``, counting ``c``."""
    best = 0
    for r in c.replies:
        candidate = deepest_reply(r)
        if candidate > best:
            best = candidate
    return 1 + best
