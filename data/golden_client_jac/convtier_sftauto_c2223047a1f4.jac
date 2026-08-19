def validate_phone_number(phone_number: Any) -> object {
    phone_number = phone_number.replace("-", "");
    if (len(phone_number) != 10) {
        return False;
    }
    if not phone_number.isdigit() {
        return False;
    }
    return True;
}



with entry {
    print(validate_phone_number('hello'));
}
