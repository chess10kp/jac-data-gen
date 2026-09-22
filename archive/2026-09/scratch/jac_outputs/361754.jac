"""
    function that do convert numbers from one base to another

    :param input_number: the number entered by the user
    :param input_base: the base user wants to convert from
    :param output_base: the base user wants to convert to
    :return converted number
    """
def main_converter(input_number: str | int, input_base: int, output_base: int) -> str {
    remainder_list = [];
    int_base_10 = 0;
    if output_base == 2 {
        return bin(input_number as int)[2:];
    } elif input_base != 10 {
        reversed_input_number = (input_number as str)[::-1];
        dictionary_hex = {'a': 10, 'b': 11, 'c': 12, 'd': 13, 'e': 14, 'f': 15};
        for (i, number) in enumerate(reversed_input_number) {
            for (key, value) in dictionary_hex.items() {
                if str(number).lower() == key {
                    number = value;
                }
            }
            int_base_10 += int(number) * (int(input_base) ** i);
        }
    } elif input_base == 10 {
        int_base_10 = int(input_number);
    }
    while int_base_10 > 0 {
        divided = int_base_10 // int(output_base);
        remainder_list.append(str(int_base_10 % int(output_base)));
        int_base_10 = divided;
    }
    if int(output_base) == 16 {
        hex_dictionary = {
            '10': 'a',
            '11': 'b',
            '12': 'c',
            '13': 'd',
            '14': 'e',
            '15': 'f'
        };
        for (i, each) in enumerate(remainder_list) {
            for (key, value) in hex_dictionary.items() {
                if each == key {
                    remainder_list[i] = value;
                }
            }
        }
    }
    return ''.join(remainder_list[::-1]);
}