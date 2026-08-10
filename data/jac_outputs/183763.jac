"""Extract recon-all stage datetime string from a log line."""
def extract_datetime_str(line: str) -> str {
    parts = line.split(' ');
    return parts[-5] + ' ' + parts[-4] + ' ' + parts[-1] + ' ' + parts[-3];
}