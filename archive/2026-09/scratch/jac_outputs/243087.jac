"""Get result of multiplying a final horizontal position by a final depth
    taking into account the aim value;
    commands(list of list[direction(str), steps(int)]): instructions"""
def get_correct_final_coordinates_product(commands: Any) -> object {
    hor = 0;
    dep = 0;
    aim = 0;
    for com in commands {
        if (com[0] == "up") {
            aim -= com[1];
        } elif (com[0] == "down") {
            aim += com[1];
        } else {
            hor += com[1];
            dep += com[1] * aim;
        }
    }
    return (hor * dep);
}