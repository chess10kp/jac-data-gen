"""Get default browser URI for autostart and desktop icon.

This default URI can be different in Live CD and installed system.
"""
def _get_browser_url(is_livecd: bool) -> str {
    if is_livecd {
        return 'http://localhost/';
    } else {
        return 'http://localhost/';
    }
}