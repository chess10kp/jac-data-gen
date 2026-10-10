The car park module (`garage.jac`) has no tests, and finance just asked us to "prove" the fee logic. Please write `garage_tests.jac` covering the `Enter` and `Leave` walkers (and `Occupancy` while you're at it):

- which level a car is assigned to and what happens when everything is full or the plate is already inside,
- the fee rules: free for the first 30 minutes, then 3 per started hour,
- leaving frees the spot, leaving with an unknown plate reports -1,
- occupancy counts per level and in total.

The code is assumed correct — tests only, no changes to `garage.jac`.
