# dbg-l3-toollib-return-deletes-tool  (debug, L3, from native/nat-l3-tool-library)

## bug0 [wrong-delete-target]: Return deletes the Tool node instead of the Lent edge
- toollib.jac: fix by restoring
```
del [edge holders[0] ->:Lent:-> tool];
```
(injected as)
```
del tool;
```

