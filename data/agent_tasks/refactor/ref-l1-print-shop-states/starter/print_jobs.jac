"""Print shop job tracking: each job moves queued -> printing -> done, or is cancelled."""

obj PrintJob {
    has name: str;
    has pages: int;
    has state: str = "queued";
}

def start_job(job: PrintJob) -> bool {
    if job.state == "queued" {
        job.state = "printing";
        return True;
    }
    return False;
}

def finish_job(job: PrintJob) -> bool {
    if job.state == "printing" {
        job.state = "done";
        return True;
    }
    return False;
}

def cancel_job(job: PrintJob) -> bool {
    if job.state == "queued" or job.state == "printing" {
        job.state = "cancelled";
        return True;
    }
    return False;
}

def status_line(job: PrintJob) -> str {
    return f"{job.name} [{job.state}]";
}

def pages_outstanding(jobs: list[PrintJob]) -> int {
    total = 0;
    for j in jobs {
        if j.state == "queued" or j.state == "printing" {
            total += j.pages;
        }
    }
    return total;
}
