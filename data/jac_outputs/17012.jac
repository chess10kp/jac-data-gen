""" Determines whether a passport is valid or not only checking the presence of the fields.

    :param passport: passport
    :return: boolean
    """
def passport_is_valid_1(passport: Any) -> object {
    return all(
        (field in passport.keys())
        for field in ['byr', 'iyr', 'eyr', 'hgt', 'hcl', 'ecl', 'pid']
    );
}