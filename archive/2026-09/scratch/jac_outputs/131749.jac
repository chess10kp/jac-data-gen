"""Convert callsign to IBP schedule time slot (0 ... 17). This is required for migration reason."""
def callsign_to_slot(callsign: str) -> int {
    return {
        '4U1UN': 0,
        'VE8AT': 1,
        'W6WX': 2,
        'KH6WO': 3,
        'KH6RS': 3,
        'ZL6B': 4,
        'VK6RBP': 5,
        'JA2IGY': 6,
        'RR9O': 7,
        'VR2B': 8,
        '4S7B': 9,
        'ZS6DN': 10,
        '5Z4B': 11,
        '4X6TU': 12,
        'OH2B': 13,
        'CS3B': 14,
        'LU4AA': 15,
        'OA4B': 16,
        'YV5B': 17
    }[callsign];
}