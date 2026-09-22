"""Parses nubase style spin information
returns dictionary {value, extrapolated}"""
def parse_isomer_spin(spin: str) -> dict[str, str | bool] {
    result = {};
    result['extrapolated'] = spin.count('#') > 0;
    if result['extrapolated'] {
        spin = spin.replace('#', ' ');
    }
    result['value'] = spin[0:8].strip();
    result['T'] = spin[8:].strip('T= ');
    return result;
}