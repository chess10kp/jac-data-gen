"""Read in service_time values from requests."""
def _get_process_times(process_times: dict[int, float], requests: list[dict[str, str | float]]) -> dict[int, float] {
    for req in requests {
        if 'service_time' in req {
            process_times[int(req['@node'])] = float(req['service_time']);
        }
    }
    return process_times;
}