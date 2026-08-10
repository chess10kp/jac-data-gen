"""
Frequency bands in the microwave range are designated by letters. This
standard is the IEEE radar bands.
"""
def get_frequency_band(wavelength: float) -> str {
    ieee_freq_band_ghz = [
        ("L", 1, 2),
        ("S", 2, 4),
        ("C", 4, 8),
        ("X", 8, 12),
        ("Ku", 12, 18),
        ("K", 18, 27),
        ("Ka", 27, 40),
        ("V", 40, 75),
        ("W", 75, 110)
    ];
    ghz = 1e-9 * 300000000 / (wavelength * 0.01);
    for (band, fmin, fmax) in ieee_freq_band_ghz {
        if ghz >= fmin and ghz <= fmax {
            return band;
        }
    }
    raise ValueError("Invalid radar wavelength. Is the wavelength in cm?");
}