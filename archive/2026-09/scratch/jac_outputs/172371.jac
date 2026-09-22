"""Expects string, returns tuple with valid data or False when data was invalid."""
def quality_check(data: str | bool) -> str | bool | None {
    if data != False {
        if "RAWMONITOR" in data {
            data = data.replace("RAWMONITOR", "");
            parts = data.split("_");
            frequency = int(parts[0]);
            temperature = int(parts[1]) / 10;
            return "{0},{1:.1f}".format(frequency, temperature);
        }
    } else {
        return False;
    }
}