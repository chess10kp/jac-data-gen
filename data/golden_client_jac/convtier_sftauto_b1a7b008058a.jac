def celsius_to_fahrenheit(celsius: Any) -> object {
    fahrenheit = ((celsius * 9) / 5) + 32;
    rounded_fahrenheit = round(fahrenheit);
    return rounded_fahrenheit;
}



with entry {
    print(celsius_to_fahrenheit(5));
    print(celsius_to_fahrenheit(10));
    print(celsius_to_fahrenheit(2));
}
