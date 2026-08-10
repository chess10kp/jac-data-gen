"""
        returns the number of the month if given a string
        and returns the name of the month if given and int
    """
def getMonth(month: int | str) -> int | str | None {
    mons = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    if `type(month) == str {
        month = (month as str)[0].upper() + (month as str)[1:3].lower();
        try {
            return mons.index(month) + 1;
        } except ValueError as err {
            print('Shall we list the months: {}'.format(err));
        }
    }
    if `type(month) == int {
        try {
            return mons[month - 1];
        } except IndexError as err {
            print('How many months are there in the year: {}'.format(err));
        }
    }
}