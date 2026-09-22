"""Process a text line the pose format."""
def processPoseLine(line: str) -> tuple[float, float, str, float] {
    space_count = 0;
    x = "";
    y = "";
    id = "";
    time_stamp = "";
    for char in line {
        if char == "," {
            char = ".";
        }
        if char == " " {
            space_count += 1;
        } elif space_count == 0 {
            time_stamp += char;
        } elif space_count == 1 {
            x += char;
        } elif space_count == 2 {
            y += char;
        } elif space_count == 7 and char != "\n" {
            id += char;
        }
    }
    return (float(x), float(y), id, float(time_stamp));
}