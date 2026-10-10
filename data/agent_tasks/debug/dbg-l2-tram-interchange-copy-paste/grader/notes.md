# dbg-l2-tram-interchange-copy-paste  (debug, L2, from native/nat-l2-tram-lines)

## bug0 [copy-paste]: second loop meant to read incoming tracks reads outgoing tracks again
- tramway.jac: fix by restoring
```
        for e in [edge here <-:Track:<-] {
```
(injected as)
```
        for e in [edge here ->:Track:->] {
```

