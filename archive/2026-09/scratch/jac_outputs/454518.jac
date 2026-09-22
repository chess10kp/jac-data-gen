"""App stop event type"""
def stop(job_id: str, event: str, action: str, resource: str, _count: int) -> tuple[str, dict[str, str]] {
    job_name = '{}:event={}:action={}'.format(resource, event, action);
    func_kwargs = dict(job_id=job_id, app_name=resource);
    return (job_name, func_kwargs);
}