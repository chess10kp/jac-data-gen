# dbg-l5-lostfound-search-expire  (debug, L5, from native/nat-l5-lost-and-found)

## bug0 [off-by-one]: items donated at exactly keep_days instead of strictly after
- app.jac: fix by restoring
```
self.today - here.found_day > self.keep_days
```
(injected as)
```
self.today - here.found_day >= self.keep_days
```

## bug1 [inconsistent-normalization]: search lower-cases the stored colour but not the query colour
- app.jac: fix by restoring
```
here.color.lower() == self.color.lower()
```
(injected as)
```
here.color.lower() == self.color
```

