"""Convert time string to seconds for saving in django."""
def parse_time(t: str) -> int {
    z = t.split(':');
    return int(z[0]) * 3600 + int(z[1]) * 60 + int(z[2]);
}