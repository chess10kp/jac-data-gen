"""Print shop job tracking: each job moves queued -> printing -> done, or is cancelled."""

enum JobState {
    QUEUED = "queued",
    PRINTING = "printing",
    DONE = "done",
    CANCELLED = "cancelled"
}

obj PrintJob {
    has name: str;
    has pages: int;
    has state: JobState = JobState.QUEUED;

    def is_open -> bool {
        return self.state in [JobState.QUEUED, JobState.PRINTING];
    }
}

def start_job(job: PrintJob) -> bool {
    if job.state == JobState.QUEUED {
        job.state = JobState.PRINTING;
        return True;
    }
    return False;
}

def finish_job(job: PrintJob) -> bool {
    if job.state == JobState.PRINTING {
        job.state = JobState.DONE;
        return True;
    }
    return False;
}

def cancel_job(job: PrintJob) -> bool {
    if job.is_open() {
        job.state = JobState.CANCELLED;
        return True;
    }
    return False;
}

def status_line(job: PrintJob) -> str {
    return f"{job.name} [{job.state.value}]";
}

def pages_outstanding(jobs: list[PrintJob]) -> int {
    return sum([j.pages for j in jobs if j.is_open()]);
}
