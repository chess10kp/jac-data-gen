"""Get an estimate wind azimuth using the winddirection string."""
def __get_windazimuth(winddirection: str | None) -> float | None {
    if not winddirection {
        return None;
    }
    dirs = {
        'N': 0,
        'NNO': 22.5,
        'NO': 45,
        'ONO': 67.5,
        'O': 90,
        'OZO': 112.5,
        'ZO': 135,
        'ZZO': 157.5,
        'Z': 180,
        'ZZW': 202.5,
        'ZW': 225,
        'WZW': 247.5,
        'W': 270,
        'WNW': 292.5,
        'NW': 315,
        'NNW': 237.5,
        'NNE': 22.5,
        'NE': 45,
        'ENE': 67.5,
        'E': 90,
        'ESE': 112.5,
        'SE': 135,
        'SSE': 157.5,
        'S': 180,
        'SSW': 202.5,
        'SW': 225,
        'WSW': 247.5
    };
    try {
        return dirs[winddirection.upper()];
    } except Exception {
        return None;
    }
}