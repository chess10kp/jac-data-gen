"""line is in the format distance,zipcode,city,state,gender,race,income,price"""
def parse_line(line: str) -> list[str] {
    parts = line.strip().split(",")[1:];
    return [str(parts[2]), str(parts[3]), str(parts[4]), str(parts[5]), str(parts[6])];
}