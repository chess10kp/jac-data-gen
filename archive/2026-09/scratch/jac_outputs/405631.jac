def boltHeadFinder(head: str | int | float) -> str {
    head_clean = str(head).lower();
    head_clean = head_clean.replace('bolt', '');
    head_clean = head_clean.replace('screw', '');
    head_clean = head_clean.replace('head', '');
    head_clean = head_clean.replace(' ', '');
    head_clean = head_clean.replace('_', '');
    head_clean = head_clean.replace('-', '');
    head_clean = head_clean.strip();
    socket_types = ['socket', 'hexagonsocketcountersunk', 'hexagononsocket', 'hexsocket'];
    if head_clean in socket_types {
        return 'socket';
    }
    return head_clean;
}