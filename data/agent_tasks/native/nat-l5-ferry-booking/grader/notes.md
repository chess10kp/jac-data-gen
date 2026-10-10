# nat-l5-ferry-booking
Capacity accounting over Holds edges with enum-dependent weights; ref uniqueness across sailings (multi-hop); node deletion; HTTP tests + start gate.
Alternative: usage() method on Sailing node with match, visit-based book/manifest, dict-mapped vehicle parse.
- Quirk: the first reference used module-level `def car_use(b: Booking)` comparing `b.vehicle == Vehicle.VAN`; under the served app (JacTestClient) it returned 0 for bookings loaded back from the store (counts only worked for the freshly built node), while the same comparison inside a node method / match worked. Server also warned the plain defs became private (not served). Reference now uses Booking methods.
- jac 0.36.1 port: `Vehicle[name]` typed as Vehicle[str] at 0.36.1 (E1053) -> vehicle_named() helper.
