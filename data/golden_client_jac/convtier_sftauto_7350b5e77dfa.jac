def check_number_type(number: Any) -> object {
    try {
        number = float(number);
        if number.is_integer() {
            if ((number % 2) == 0) {
                return "Even";
            } else {
                return "Odd";
            }
        } else {
            return "Decimal";
        }
    } except ValueError {
        return "Invalid number";
    }
}



with entry {
    print(check_number_type('hello'));
    print(check_number_type(5));
    print(check_number_type(10));
}
