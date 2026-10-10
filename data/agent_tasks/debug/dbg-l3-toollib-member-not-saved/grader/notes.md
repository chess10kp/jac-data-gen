# dbg-l3-toollib-member-not-saved  (debug, L3, from native/nat-l3-tool-library)

## bug0 [persistence-not-attached]: new Member nodes are created but never connected to root, so the same card becomes a new member on every checkout
- toollib.jac: fix by restoring
```
            member = root ++> Member(card=self.card);
```
(injected as)
```
            member = Member(card=self.card);
```

