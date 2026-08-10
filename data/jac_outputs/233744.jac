"""Input float, Returns formatted dollars($x,xxx.xx)"""
def format_dollars(amount: int | float) -> str {
    balance = '{:.2f}'.format(amount);
    parts = balance.split('.');
    reversed_digits = parts[0][::-1];
    new_thing = '';
    for i in range(1, len(reversed_digits) + 1) {
        if (i - 1) % 3 == 0 and i != 1 {
            new_thing += ',';
        }
        new_thing += reversed_digits[i - 1];
    }
    '$' + new_thing[::-1] + '.' + parts[1]
}