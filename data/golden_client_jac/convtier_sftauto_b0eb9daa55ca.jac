def integerToRoman(num: Any) -> object {
    decimalValues = [1000, 900, 500, 400, 100, 90, 50, 40, 10, 9, 5, 4, 1];
    romanSymbols = [
        "M",
        "CM",
        "D",
        "CD",
        "C",
        "XC",
        "L",
        "XL",
        "X",
        "IX",
        "V",
        "IV",
        "I"
    ];
    romanNumeral = "";
    for i in range(len(decimalValues)) {
        while (num >= decimalValues[i]) {
            romanNumeral += romanSymbols[i];
            num -= decimalValues[i];
        }
    }
    return romanNumeral;
}



with entry {
    print(integerToRoman(5));
    print(integerToRoman(10));
    print(integerToRoman(2));
}
