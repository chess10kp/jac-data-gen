"""Removes code blocks from code."""
def _cleanup_eval(body: Any) -> object {
    if (body.startswith('```') and body.endswith('```')) {
        return '\n'.join(body.split('\n')[1:-1]);
    }
    return body.strip('` \n');
}