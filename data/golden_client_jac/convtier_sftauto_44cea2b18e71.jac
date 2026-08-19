def hex_to_int(hex_string: Any) -> object {
    try {
        decimal = int(hex_string, 16);
        return decimal;
    } except ValueError {
        if hex_string.startswith('-') {
            try {
                decimal = int(hex_string[1:], 16);
                return -decimal;
            } except ValueError {
                return None;
            }
        } else {
            return None;
        }
    }
}



with entry {
    print(hex_to_int('abcabc'));
}
