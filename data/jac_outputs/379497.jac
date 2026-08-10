"""Determine whether the identifier matches any project context criteria."""
def is_identifier_match(identifier: str, project: dict) -> bool {
    matches = (
        '{:.0f}'.format(project.get('index', -1) + 1),
        project.get('uid', ''),
        project.get('name', '')
    );
    return any(identifier == m for m in matches);
}