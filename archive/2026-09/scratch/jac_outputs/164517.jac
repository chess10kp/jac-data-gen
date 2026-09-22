"""Helper to return a single comment with status_code."""
def get_single_comment_response(status_code: int) -> tuple[bytes, int, dict[str, str]] {
    if status_code == 304 {
        return (b'', 304, {'content-type': 'application/json'});
    }
    return (
        b'{"user": {"login": "miketaylr","avatar_url": "https://avatars1.githubusercontent.com/u/67283?v=4"},"created_at": "2016-07-28T14:41:43Z","body_html": "<p>test</p>"}',
        status_code,
        {'content-type': 'application/json'}
    );
}