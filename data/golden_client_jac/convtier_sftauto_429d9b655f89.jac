def format_number(num: Any) -> object {
    if ((num % 7) == 0) {
        formatted_num = '{:,.5f}'.format(num).replace(',', ' ');
        return formatted_num[:-1] if (formatted_num[-1] == '0') else formatted_num;
    } else {
        return "Invalid input! The number should be divisible by 7.";
    }
}



with entry {
    print(format_number(5));
    print(format_number(0));
    print(format_number(7));
}
