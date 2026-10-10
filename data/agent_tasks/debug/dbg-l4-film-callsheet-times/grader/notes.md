# dbg-l4-film-callsheet-times  (debug, L4, from native/nat-l4-film-callsheet)

## bug0 [inverted-comparison]: earliest-scene tracking keeps the latest scene instead
- callsheet.jac: fix by restoring
```
here.start_min < self.first_scene[key]
```
(injected as)
```
here.start_min > self.first_scene[key]
```

## bug1 [wrong-attribute]: distinct locations counted by scene number instead of location
- callsheet.jac: fix by restoring
```
self.places.add(here.location);
```
(injected as)
```
self.places.add(here.number);
```

