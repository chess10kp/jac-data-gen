I'm modelling a river catchment in `watershed.jac`. Each stretch of river is a `Reach` node; water moving from one reach into the next is a `FlowsInto` edge pointing **downstream**. Some channels only run in the wet season (`seasonal=True` on the edge). Monitoring stations are separate `Station` nodes linked to the reach they sample with a `Samples` edge (station → reach).

I need a walker `UpstreamLoad` that I can spawn on a `Station`:

```
w = station spawn UpstreamLoad(dry_season=True);
```

It should work out everything that drains to the reach that station samples:

- Start from the sampled reach and follow `FlowsInto` edges **upstream** (i.e. against the edge direction), as far as they go.
- When `dry_season` is true, ignore seasonal channels completely — water doesn't come through them, and nothing upstream of them counts unless it also reaches us through a permanent channel. In the wet season every channel counts.
- Braided channels mean the same reach can be reached by several routes; count each reach once.
- Sum `load_kg` over the sampled reach itself plus every upstream reach found, into a `total_kg: float` field.
- Report once at the end: the list of contributing reach names (including the sampled reach), sorted alphabetically.

A station that isn't linked to any reach should report an empty list with `total_kg` 0. The node/edge declarations and `connect_reach` helper should stay as they are.
