def csv_second_field(row: str) -> str {
    return row.split(",")[1].strip();
}

with entry {
    for x in ["a,b,c", "name, age, city", "1,2,3", "x, y"] {
        print(csv_second_field(x));
    }
}
