#* Inocula C2 — NOISY track (Phase 4)
   =============================================================
   NOISY track semantics:

   1. C2 (Laptop B) has locked a target and the operator pressed
      RUN OPERATION with track="noisy" (or "both").
   2. C2 opens an SSH session to the Pi Scout (no inbound port on
      the Pi — C2 reaches out):
          ssh -o StrictHostKeyChecking=accept-new \
              -o BatchMode=yes \
              inocula@<pi_host> \
              'sudo /home/inocula/Inocula_Final/scout/bt_clone.sh <target_mac>'
      bt_clone.sh wraps ``btmgmt public-addr <mac>`` (one-shot MAC
      clone; idempotent). Exit 0 = clone registered, non-zero =
      failure (we still chain stealth so the demo lands).
   3. Once the MAC clone registers, Laptop A's Inocula Sentinel
      duplicate-MAC detector (Phase 2, sentinel/sentinels/bt.jac)
      fires — this is the "noise" we intentionally trip.
   4. After the noisy step, the stealth track is chained as the
      "impact" phase so the demo still lands the payload POST
      even if the noisy trip didn't remediate fast enough.
   5. If the noisy step fails outright, stealth still runs and the
      operation is reported as `noisy_ok=False, stealth_chained=True`.

   Implementation
   --------------
   The real logic lives in Python for testability and to keep
   subprocess/network code out of the walker layer:
       c2/adapters/track_ops.py::fire_noisy(...)

   c2/main.jac imports it as `track_fire_noisy` and calls it
   from inside walker:pub run_operation with `then_stealth` set to
   a closure that invokes `track_fire_stealth` after the SSH leg.

   This file is kept as a documentation anchor so anyone grepping
   the repo for "noisy track" lands on the contract. *#
