"""Grep out all lines with scancel example."""
def job_ids(log_stream: list[str]) -> list[str] {
    id_rows = [line for line in log_stream if 'scancel' in line];
    return [id_row.strip()[-7:-1] for id_row in id_rows];
}