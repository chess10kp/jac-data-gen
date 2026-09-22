"""try to format a number to formatted string with thousands"""
def formatted_number(number: int | str) -> str {
    try {
        number = int(number);
        if number < 0 {
            return '-' + formatted_number(-number);
        }
        result = '';
        while number >= 1000 {
            div = divmod(number, 1000) as tuple[int, int];
            number = div[0];
            number2 = div[1];
            result = ",%03d%s" % (number2, result);
        }
        return "%d%s" % (number, result);
    } except Exception {
        return "";
    }
}