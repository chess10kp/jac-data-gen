#* Inocula C2 — STEALTH track (Phase 4)
   =============================================================
   STEALTH track semantics:

   1. C2 (Laptop B) has locked a target and the operator pressed
      RUN OPERATION with track="stealth" (or "both").
   2. C2 issues a POST to the Sentinel on Laptop A at:
          POST http://<laptop_a_ip>:8787/walker/trigger_payload
      with headers:
          X-Inocula-Token: <shared_secret>
          Content-Type: application/json
      and body (see shared/protocol.md §2 "trigger_payload"):
          { "force": false,
            "origin": "c2_stealth",
            "operation_id": "op_<ts>",
            "protocol_version": 1 }
   3. Sentinel honors its own cooldown + armed state. In Phase 3+
      trigger_payload is a **bait endpoint** — it records the hit
      into trigger_payload_access.ndjson and refuses to fire.
      The landing is done by the Sentinel's own
      NetworkSentinel+classify_and_respond chain once it spots the
      recorded POST from a non-whitelisted IP.
   4. This "trips the defense on purpose" to demonstrate the
      detection gap the Inocula paper covers.

   Implementation
   --------------
   The real logic lives in Python for testability and to keep
   subprocess/network code out of the walker layer:
       c2/adapters/track_ops.py::fire_stealth(...)

   c2/main.jac imports it as `track_fire_stealth` and calls it
   from inside walker:pub run_operation. There is no standalone
   Jac walker for the track — the track IS the sequence of
   adapter calls that run_operation dispatches.

   This file is kept as a documentation anchor so anyone grepping
   the repo for "stealth track" lands on the contract. *#
