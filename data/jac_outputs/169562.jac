"""Pulls date in form YYYMMDD from id."""
def extractdate(id: str) -> int {
    date = id[1:9];
    return int(date);
}