import os;
import time;

def maybe_run_periodic_task(task_id: str) -> bool {
    key = f'task_dbnce:{task_id}';
    payload = {'pod': os.environ.get('HOSTNAME', 'local'), 'ts': time.time()};

    if not _kv.set_nx_with_ttl(key, payload, ttl=60) {
        return False;  # Another pod already ran it within the last 60s.
    }

    try {
        run_task(task_id);
        return True;
    } except Exception as e {
        # Roll back the claim so the next tick can retry instead of being
        # debounced away by a marker for work that never completed.
        _kv.delete_if_equals(key, payload);
        raise;
    }
}
