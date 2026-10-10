The greenhouse app is getting the beds confused:

- Every time we plant something a new bed appears. We have three physical beds but the database now lists eleven B1s and B2s, and `PlantIn` always reports 1 plant in the bed.
- Uprooting the mint in B1 also pulled the mint out of B2.

Both should be scoped to the bed code we pass in.
