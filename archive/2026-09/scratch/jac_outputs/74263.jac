"""Discard certain scenes, which would then be treated as absence."""
def discard_sessions_by_scene(sessions: list[tuple[str, str]], scene: str) -> list[tuple[str, str]] {
    return [
        session
        for session in sessions
        if not session[0].startswith(scene)
    ];
}