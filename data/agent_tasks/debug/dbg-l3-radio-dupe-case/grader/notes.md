# dbg-l3-radio-dupe-case  (debug, L3, from native/nat-l3-radio-contest-log)

## bug0 [inconsistent-normalization]: dupe check compares the stored upper-case call against the raw (unnormalised) input
- contest.jac: fix by restoring
```
[book ->:Logged:->[?:Qso, call == sign]]
```
(injected as)
```
[book ->:Logged:->[?:Qso, call == self.call]]
```

