Can you set up an RSVP endpoint for our community events? Jac service project is already created here.

`POST /walker/rsvp` (public walker named `rsvp`) with JSON body:

```json
{"event": "spring-cleanup", "guest": "Dana Lee", "attending": true, "plus_ones": 1}
```

- `plus_ones` is optional (default 0) and must be between 0 and 3, otherwise report `{"error": "..."}` and don't record anything.
- A guest can change their RSVP; the latest one replaces the earlier one. Guest names match case-insensitively after trimming, but keep the spelling from their most recent RSVP.
- Store events and guests on the graph under root (an event node, guest nodes, and edges between them).
- The walker reports the event summary:

```json
{"event": "spring-cleanup", "headcount": 5, "attending": ["Dana Lee", "Sam"], "declined": ["Alex"]}
```

`headcount` counts attending guests plus their plus-ones. Name lists are sorted case-insensitively.

Please include tests.
