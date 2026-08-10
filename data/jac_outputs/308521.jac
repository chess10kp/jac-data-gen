"""Check whether board upload auto-reset is enabled."""
def checke_do_reset(board_info: dict[str, str]) -> bool {
    return board_info.get('upload.auto_reset', '') == 'true';
}