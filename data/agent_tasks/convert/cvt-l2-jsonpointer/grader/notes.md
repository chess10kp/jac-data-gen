# cvt-l2-jsonpointer
Source: jsonpointer 3.2.0 sdist (Stefan Kögl, Modified BSD). Hidden tests port tests.py
(spec examples, round trip, str/repr, eq/hash, contains/join, wrong input, to_last, set in/out of
place, alt indexable types via __getitem__/__setitem__ objs) + doctests (defaults, escape, pairwise).
Quirks: `default` and `root` are Jac keywords; Mapping/Sequence are ambient (E1125 if imported from
collections.abc); `isinstance(x, Sequence)` doesn't narrow to something with .append (use list).
Negatives: unescape order, leading-zero indexes, missing deepcopy, contains reversed, '-' returns list,
default ignored.
