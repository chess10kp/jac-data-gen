import os;
import time;
import from uuid { uuid4 }
import from jac_scale.lib { kvstore }

glob _kv = kvstore(db_name='myapp', db_type='redis');

def with_repo_lock(repo_id: str, action: str) -> dict {
    fence = str(uuid4());
    payload = {'fence': fence, 'pod': os.environ.get('HOSTNAME', 'local')};

    # Acquire: retry up to ~25s, give up if contention persists.
    deadline = time.time() + 25.0;
    acquired = False;
    while time.time() < deadline {
        if _kv.set_nx_with_ttl(f'repo_lock:{repo_id}', payload, ttl=30) {
            acquired = True;
            break;
        }
        time.sleep(0.2);
    }
    if not acquired {
        return {'success': False, 'error': 'lock contention timeout'};
    }

    try {
        return run_protected_op(repo_id, action);
    } finally {
        # Release: compare-and-delete. Safe even if our TTL already expired
        # and another pod owns the key now; the value mismatch makes it a no-op.
        _kv.delete_if_equals(f'repo_lock:{repo_id}', payload);
    }
}
