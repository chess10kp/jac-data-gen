def celsius_to_fahrenheit(celsius: Any) -> object {
    fahrenheit = 32;
    temperature_difference = celsius - 0;
    fahrenheit += temperature_difference * 1.8;
    return fahrenheit;
}



with entry {
    print(celsius_to_fahrenheit(5));
    print(celsius_to_fahrenheit(10));
    print(celsius_to_fahrenheit(2));
}
