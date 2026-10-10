Our team votes on lunch every Friday in Slack and I want a backend for it. Can you build it in this Jac service project?

Just one endpoint: a public walker `cast_vote` → `POST /walker/cast_vote` with body `{"poll": "...", "voter": "...", "choice": "..."}`.

- Polls are created on the fly the first time someone votes in them.
- Each voter has one vote per poll. If they vote again, their vote moves to the new choice.
- Choices are compared case-insensitively and stored lower-case ("Tacos" and "tacos" are the same).
- The response (the walker's report) is the current state of that poll: `{"poll": "<poll>", "tallies": {"<choice>": <count>, ...}, "leader": "<choice with most votes>"}`. Choices that drop to zero votes disappear from `tallies`. If there's a tie for the lead, pick the alphabetically first choice.

Model it as a graph (poll node, voter/vote nodes or edges — your call) stored under root so it persists. Add tests too.
