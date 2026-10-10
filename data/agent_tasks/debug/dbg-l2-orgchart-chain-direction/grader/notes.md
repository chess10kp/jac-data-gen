# dbg-l2-orgchart-chain-direction  (debug, L2, from app/app-l2-org-chart)

## bug0 [edge-direction]: chain of command follows Manages edges downward instead of upward
- orgchart.jac: fix by restoring
```
        visit [here <-:Manages:<-];
```
(injected as)
```
        visit [here ->:Manages:->];
```

