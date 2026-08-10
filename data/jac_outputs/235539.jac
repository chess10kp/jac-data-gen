"""Return the (engine display name, engine name) for the job."""
def _get_engine_names(job_name: str) -> tuple[str, str] {
    if job_name.startswith('afl_') {
        return ('AFL', 'afl');
    }
    if job_name.startswith('libfuzzer_') {
        return ('libFuzzer', 'libFuzzer');
    }
    return ('Unknown', 'Unknown');
}