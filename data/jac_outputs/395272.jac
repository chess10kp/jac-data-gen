"""Return course start date from a fall|spring|summerYYYY path prefix."""
def path_to_startdate(path: str) -> str {
    s = str(path.split('/')[0]);
    if s.startswith('fall') {
        return s[-4:] + '-09-01';
    } elif s.startswith('spring') {
        return s[-4:] + '-01-01';
    } elif s.startswith('summer') {
        return s[-4:] + '-06-01';
    }
    return '';
}