# dbg-l3-library-copies-never-drop  (debug, L3, from app/app-l3-library-loans)

## bug0 [edge-direction]: available copies count Loan edges leaving the book (there are none) instead of arriving at it
- main.jac: fix by restoring
```
return b.copies - len([edge b <-:Loan:<-]);
```
(injected as)
```
return b.copies - len([edge b ->:Loan:->]);
```

