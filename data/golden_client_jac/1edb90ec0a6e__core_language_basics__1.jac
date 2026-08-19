def maybe_run_periodic_task(task_id: str) -> bool {
    payload = {'pod': os.environ.get('HOSTNAME', 'local'), 'ts': time.time()};
    if _kv.set_nx_with_ttl(f'task_dbnce:{task_id}', payload, ttl=60) {
        run_task(task_id);
        return True;
    }
    return False;  # Another pod already ran it within the last 60s.
}
