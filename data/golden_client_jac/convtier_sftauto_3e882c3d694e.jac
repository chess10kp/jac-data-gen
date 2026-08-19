def format_phone_number(phone_number: Any) -> object {
    phone_number = ''.join(filter(str.isdigit, str(phone_number)));
    if (len(phone_number) != 10) {
        return "Invalid phone number";
    }
    formatted_number = (
        "+1-" + phone_number[:3] + "-" + phone_number[3:6] + "-" + phone_number[6:]
    );
    return formatted_number;
}



with entry {
    print(format_phone_number('hello'));
}
