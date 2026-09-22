"""Given a list of months, create the string representing the sequence."""
def getMonthString(my_list: int | list[int] | tuple[int, ...]) -> str {
    if not isinstance(my_list, (list, tuple)) {
        my_list = [my_list];
    }
    dic = {
        1: 'JANUARY',
        2: 'FEBRUARY',
        3: 'MARCH',
        4: 'APRIL',
        5: 'MAY',
        6: 'JUNE',
        7: 'JULY',
        8: 'AUGUST',
        9: 'SEPTEMBER',
        10: 'OCTOBER',
        11: 'NOVEMBER',
        12: 'DECEMBER'
    };
    out = [];
    for i in my_list {
        out.append(dic[i][0]);
    }
    if len(out) == 1 {
        out = [dic[my_list[0]]];
    }
    return "".join(out);
}