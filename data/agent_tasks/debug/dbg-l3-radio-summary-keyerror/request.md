`BandSummary` crashes as soon as there's anything in the log:

```
KeyError: 'B80M'
```

With an empty log it's fine. Scoring still works. It should report a dict of band name → number of contacts for each band we've logged on.
