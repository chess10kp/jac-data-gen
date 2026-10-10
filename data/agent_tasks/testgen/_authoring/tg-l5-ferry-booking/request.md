I maintain the ferry reservation service in `app.jac`. Could you write unit tests for it in `ferry_tests.jac`? Spawning the walkers directly on `root` is fine (no need to go through HTTP for this one).

What matters most: deck accounting (a VAN uses 2 car lanes, a CAR 1, foot passengers use seats), "sold out" when either limit would be exceeded, the order in which booking errors are checked (unknown sailing → duplicate ref → bad vehicle → sold out), duplicate refs across sailings, cancellation freeing space, and the `manifest` / `day_summary` outputs. Don't change `app.jac`.
