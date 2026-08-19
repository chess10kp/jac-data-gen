def convert_temp(temperature: Any) -> object {
    try {
        fahrenheit = float(temperature);
        celsius = ((fahrenheit - 32) * 5) / 9;
        return round(celsius, 2);
    } except ValueError {
        return "Invalid input. Temperature must be a number.";
    }
}



with entry {
    print(convert_temp('hello'));
    print(convert_temp(5));
    print(convert_temp(10));
}
