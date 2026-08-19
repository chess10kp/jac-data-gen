def celsius_to_fahrenheit(celsius: Any) -> object {
    fahrenheit = celsius << 1;
    fahrenheit += celsius + (celsius // 2) + 32;
    return fahrenheit;
}



with entry {
    print(celsius_to_fahrenheit(5));
    print(celsius_to_fahrenheit(10));
    print(celsius_to_fahrenheit(2));
}
