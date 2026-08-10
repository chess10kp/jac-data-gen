"""Creates a job filter from |job|."""
def _get_filter_from_job(job: str | int | float | bool | None) -> list[str] | None {
    return [str(job)] if job else None;
}