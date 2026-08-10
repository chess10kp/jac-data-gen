"""Return roman numeral for an integer."""
def integerToRoman(num: int) -> str {
    roman: list[tuple[int, str]] = [
        (1000, "M"),
        (900, "CM"),
        (500, "D"),
        (400, "CD"),
        (100, "C"),
        (90, "XC"),
        (50, "L"),
        (40, "XL"),
        (10, "X"),
        (9, "IX"),
        (5, "V"),
        (4, "IV"),
        (1, "I")
    ];
    parts: list[str] = [];
    for (r, ltr) in roman {
        x = num // r;
        parts.append(ltr * x);
        num -= r * x;
        if num <= 0 {
            break;
        }
    }
    return "".join(parts);
}