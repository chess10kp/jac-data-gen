"""
    >:param str validated_letter: A capital letter, that will be used to generate the
    list of strings needed to print out the diamond.

    >**Returns:** A list a strings that contains the correct spacing for printing
    the diamond.

    build_diamond is used to generate the list of strings needed to print the diamond structure.
    It takes a single argument of a letter (in string format), and returns a list of strings.

    This list of strings can then be printed with newline characters (using join) to output the
    diamond structure.

    """
def build_diamond(validated_letter: str) -> list[str] {
    a_ascii = ord('A');
    rows = ord(validated_letter) - a_ascii + 1;
    diamond = [];
    for row in list(range(rows)) + list(reversed(range(rows - 1))) {
        if row == 0 {
            diamond.append(
                '{: <{w1}}{current_letter}'.format(
                    '', w1=rows - 1, current_letter=chr(a_ascii + row)
                )
            );
        } else {
            diamond.append(
                '{: <{w1}}{current_letter}{: <{w2}}{current_letter}'.format(
                    '',
                    '',
                    w1=rows - row - 1,
                    current_letter=chr(a_ascii + row),
                    w2=row * 2 - 1
                )
            );
        }
    }
    return diamond;
}