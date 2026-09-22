"""Seperates the interface input from the user into the name and number ex.
    Gi1/0/1 becomes ('Gi', '1/0/1') or GigabitEthernet1/0/1 becomes ('GigabitEthernet', '1/0/1')"""
def parse_input(input: str) -> tuple[str, str] {
    interface_name = '';
    interface_number = '';
    x = 0;
    for letter in input {
        if letter.isdigit() {
            interface_number = input[x:];
            break;
        } else {
            interface_name += letter;
        }
        x += 1;
    }
    return (interface_name.strip(' '), interface_number.strip(' '));
}