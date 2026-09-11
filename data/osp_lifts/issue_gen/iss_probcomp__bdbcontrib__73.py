"""Probabilistic-composer column DAG ancestry queries.

probcomp/bdbcontrib#73: the composer registers generators (columns) into a
DAG of parent links and answers ad-hoc queries by walking that DAG with an
adjacency list and recursive descent -- column_dependence_probability alone is
"a simple graph walk in the DAG". The lifted surface keeps the walk results as
sets: ancestry closures, dependence reachability, and the Markov blanket of a
column (its parents, children, and co-parents).
"""


class Composer:
    """In-memory registry of generator columns and their parent links."""

    def __init__(self):
        self.columns = {}   # name -> list of parent names

    def create_generator(self, name, parents=()):
        """Register ``name`` depending on ``parents``; unknown parents fail."""
        for p in parents:
            if p not in self.columns:
                raise KeyError(p)
        self.columns[name] = list(parents)

    def _walk(self, start, links):
        seen = set()
        stack = list(links(start))
        while stack:
            cur = stack.pop()
            if cur in seen or cur == start:
                continue
            seen.add(cur)
            stack.extend(links(cur))
        return seen

    def _parents(self, name):
        return self.columns.get(name, [])

    def _children(self, name):
        return sorted(c for c, ps in self.columns.items() if name in ps)

    def ancestors(self, name):
        """All transitive parents of ``name`` (sorted set)."""
        if name not in self.columns:
            return []
        return sorted(self._walk(name, self._parents))

    def descendants(self, name):
        """All transitive children of ``name`` (sorted set)."""
        if name not in self.columns:
            return []
        return sorted(self._walk(name, self._children))

    def depends_on(self, ancestor, descendant):
        """True when ``descendant`` transitively depends on ``ancestor``."""
        if descendant not in self.columns:
            return False
        return ancestor in self._walk(descendant, self._parents)

    def markov_blanket(self, name):
        """Parents + children + co-parents of ``name`` (sorted set).

        Unknown columns yield an empty blanket.
        """
        if name not in self.columns:
            return []
        blanket = set(self._parents(name)) | set(self._children(name))
        for child in self._children(name):
            blanket.update(self._parents(child))
        blanket.discard(name)
        return sorted(blanket)
