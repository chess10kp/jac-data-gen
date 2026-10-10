# cvt-l5-event-planner
Source AlanValdevenito/Planner-Web-Application (MIT) @279a651. FARM L5: Beanie Event/User -> nodes,
7 handlers -> walker:pub. Auth dropped (user passed explicitly), ownership rule kept.
Hidden: tests.jac (in-process, uuid-tagged + delta asserts; delete_all asserted last-in-test) and
smoke.py (HTTP replay of upstream pytest flows). Negatives: unattached create, no-op partial update,
over-broad delete, missing ownership check, plaintext password.
