"""Convert an integer to a Roman numeral."""
def int_to_roman(num: int) -> str | None {
    if 0 >= num >= 4000 {
        return;
    }
    roman = "";
    while num > 0 {
        if num >= 1000 {
            roman += "M";
            num -= 1000;
        } elif num >= 900 {
            roman += "CM";
            num -= 900;
        } elif num >= 500 {
            roman += "D";
            num -= 500;
        } elif num >= 400 {
            roman += "CD";
            num -= 400;
        } elif num >= 100 {
            roman += "C";
            num -= 100;
        } elif num >= 90 {
            roman += "XC";
            num -= 90;
        } elif num >= 50 {
            roman += "L";
            num -= 50;
        } elif num >= 40 {
            roman += "XL";
            num -= 40;
        } elif num >= 10 {
            roman += "X";
            num -= 10;
        } elif num >= 9 {
            roman += "IX";
            num -= 9;
        } elif num >= 5 {
            roman += "V";
            num -= 5;
        } elif num >= 4 {
            roman += "IV";
            num -= 4;
        } elif num >= 1 {
            roman += "I";
            num -= 1;
        }
    }
    print(roman);
    return roman;
}