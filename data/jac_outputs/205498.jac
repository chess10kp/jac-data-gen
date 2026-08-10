"""Returns job class."""
def get_job_class(job: dict[str, str]) -> str | None {
    if '_class' in job {
        if job['_class'] == 'com.cloudbees.hudson.plugins.folder.Folder' {
            return 'folder';
        }
    }
    if 'DFG-' in job['name'] {
        return 'DFG';
    } elif 'util' in job['name'] {
        return 'utility';
    }
}