def validate_phone_number(phone_number: Any) -> object {
    if ((len(phone_number) != 12) and (len(phone_number) != 10)) {
        return False;
    }
    if (
        (len(phone_number) == 12)
        and ((phone_number[3] != '-') or (phone_number[6] != '-'))
    ) {
        return False;
    }
    if (
        (len(phone_number) == 12)
        and not phone_number[:3].isdigit()
        and not phone_number[4:6].isdigit()
        and not phone_number[7:].isdigit()
    ) {
        return False;
    }
    if ((len(phone_number) == 10) and not phone_number.isdigit()) {
        return False;
    }
    return True;
}



with entry {
    print(validate_phone_number('hello'));
}
