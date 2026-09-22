"""get the latest output that each archive method produced for link"""
def latest_output(link: Any, status: Any = None) -> object {
    latest = {
        'title': None,
        'favicon': None,
        'wget': None,
        'warc': None,
        'pdf': None,
        'screenshot': None,
        'dom': None,
        'git': None,
        'media': None,
        'archive_org': None
    };
    for archive_method in latest.keys() {
        history = link.get('history', {}).get(archive_method) or [];
        history = filter(lambda (result: Any) { result['output']; }, reversed(history));
        if (status is not None) {
            history = filter(
                lambda (result: Any) { (result['status'] == status); }, history
            );
        }
        history = `list(history);
        if history {
            latest[archive_method] = history[0]['output'];
        }
    }
    return latest;
}