"""Calculate the CPU percentage for a process running in a particular scenario."""
def cpu_usage_for_process(results: list[dict[str, str | int | float | dict[str, str]]], process: str) -> float | None {
    process_results = [
        r
        for r in results
        if r['metric']['type'] == 'cputime' and r['process'] == process
    ];
    cpu_values = sum(r['value'] for r in process_results);
    wallclock_values = sum(r['wallclock'] for r in process_results);
    if wallclock_values > 0 {
        return float(cpu_values) / wallclock_values;
    }
    return None;
}