"""Token hierarchy: subtoken claim inheritance and revocation cascade.

Before-code synthesized from OpenCHAMI/tokensmith#37: child tokens link to
parents via ``parent_token_id`` and inherit MFA claims (amr/acr/auth_time)
from their ancestor chain, may only restrict (never elevate) parent scopes,
and revoking a token must invalidate every descendant. The registry keeps
id-keyed parent pointers plus a children adjacency map; inheritance and
revocation are hand-rolled walks over those structures.
"""


class RevocationError(ValueError):
    """The target token is already revoked."""


class ScopeViolation(ValueError):
    """A child tried to elevate scopes beyond its parent."""


class TokenRegistry:
    def __init__(self):
        self.parent_of = {}     # token_id -> parent id | None
        self.children_of = {}   # token_id -> [child ids]
        self.revoked = set()
        self.claims = {}        # token_id -> {"amr": [...], "acr": str, "auth_time": int}
        self.scopes_of = {}

    def issue(self, token_id, scopes, claims=None, parent_id=None):
        if parent_id is not None:
            if parent_id not in self.parent_of or parent_id in self.revoked:
                raise KeyError("unknown or revoked parent token")
            extra = set(scopes) - set(self.scopes_of[parent_id])
            if extra:
                raise ScopeViolation("elevated scopes: %s" % sorted(extra))
        self.parent_of[token_id] = parent_id
        if parent_id is not None:
            self.children_of.setdefault(parent_id, []).append(token_id)
        self.children_of.setdefault(token_id, [])
        self.claims[token_id] = dict(claims or {})
        self.scopes_of[token_id] = set(scopes)

    def _ancestor_chain(self, token_id):
        """Parent pointers walked by hand; cycle guard via seen set."""
        chain = []
        seen = {token_id}
        cur = self.parent_of.get(token_id)
        while cur is not None:
            if cur in seen:
                break
            seen.add(cur)
            chain.append(cur)
            cur = self.parent_of.get(cur)
        return chain

    def effective_claims(self, token_id):
        """Nearest-wins merge of claims along the ancestor chain."""
        merged = {}
        for anc in reversed(self._ancestor_chain(token_id)):
            for k, v in self.claims[anc].items():
                merged[k] = v
        for k, v in self.claims[token_id].items():
            merged[k] = v
        return merged

    def revoke(self, token_id):
        """Revoking a token invalidates ALL descendants (cascade).

        Explicit stack walk over the children map collects the cascade
        set first; the sweep applies revocation afterwards.
        """
        if token_id in self.revoked:
            raise RevocationError("already revoked")
        collected = []
        stack = [token_id]
        seen = set()
        while stack:
            cur = stack.pop()
            if cur in seen:
                continue
            seen.add(cur)
            collected.append(cur)
            stack.extend(self.children_of.get(cur, []))
        for t in collected:
            self.revoked.add(t)
        return sorted(collected)

    def is_active(self, token_id):
        """Active means unrevoked AND no revoked ancestor."""
        if token_id in self.revoked:
            return False
        for anc in self._ancestor_chain(token_id):
            if anc in self.revoked:
                return False
        return True
