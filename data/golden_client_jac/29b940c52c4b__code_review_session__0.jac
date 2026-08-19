node AuditEntry {
    has action: str,
        ts: float;
}

import time;

with entry {
    # Actual mutation -- now there's something to persist.
    root ++> AuditEntry(action="startup", ts=time.time());

    try {
        # Force the write to the database at this checkpoint instead of
        # waiting for the implicit end-of-context flush.
        commit();
        print("audit entry committed");
    } except Exception as e {
        print(f"commit failed, changes may not be persisted: {e}");
        raise;
    }
}
