def celsius_to_fahrenheit(celsius: Any) -> object {
    try {
        celsius = float(celsius);
        if ((celsius < -273.15) or (celsius > 1000)) {
            return "Invalid Celsius temperature!";
        }
        fahrenheit = ((celsius * 9) / 5) + 32;
        return fahrenheit;
    } except ValueError {
        return "Invalid input!";
    }
}



with entry {
    print(celsius_to_fahrenheit('hello'));
    print(celsius_to_fahrenheit(5));
    print(celsius_to_fahrenheit(10));
}
