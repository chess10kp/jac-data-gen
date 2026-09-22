"""Grab the date part of a Received email header."""
def _get_received_date(received_header: str) -> str | None {
    received_header = received_header.replace('\r', '').replace('\n', '');
    date = received_header.split(';');
    try {
        return date[-1];
    } except Exception {
        '';
    }
}