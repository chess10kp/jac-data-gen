"""Return a formatted string of a server's power state."""
def _format_servers_list_power_state(state: int) -> str {
    power_states = [
        'NOSTATE',
        'Running',
        '',
        'Paused',
        'Shutdown',
        '',
        'Crashed',
        'Suspended'
    ];
    try {
        return power_states[state];
    } except Exception {
        return 'N/A';
    }
}