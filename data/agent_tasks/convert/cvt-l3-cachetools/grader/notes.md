# cvt-l3-cachetools
Source: cachetools 7.2.1 (MIT, Thomas Kemmer), PyPI sdist; trimmed to Cache/FIFO/LFU/LRU/TTL + keys.
Upstream tests are not in the sdist; hidden tests (10) were written against upstream semantics and
every expected value was cross-checked by running the upstream package (python3 -I).
Negatives: LRU read doesn't refresh, FIFO re-set keeps old position, overwrite size not diffed,
TTL `in` ignores expiry, LFU reads not counted, typedkey ignores kwarg types.
Jac quirks: MutableMapping/Mapping are ambient (import = E1125); a module with no anchoring Python
import is placed native and gets per-ability demotions (`jac explain placement`) -- cachekeys
imports `operator` (used for the sort key) which keeps it on the server codespace; bare `tuple`
annotations are E1036, and upstream's private hash-caching `_HashedTuple` became a plain tuple
(same equality/hash).
