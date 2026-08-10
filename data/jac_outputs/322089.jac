"""Parse a user line."""
def parse_user(line: str, sep: str = ',') -> tuple[int, str] {
    fields = line.strip().split(sep);
    user_id = int(fields[0]);
    gender = fields[1];
    return (user_id, gender);
}