""" utility to parse the job ID from the worker name

    template: 'prefix--jobid--suffix'
    """
def _job_id_from_worker_name(name: str) -> str {
    (_, job_id, _) = name.split("--");
    job_id
}