"""Helper function for csv_to_records to convert list with three
[lname,fname,age_str] to {'last_name': lname, 'first_name': fname, 'age': age_int}.

Raises ValueError if three_list does not have three entries or age is not int-convertible.
"""
def three_list_to_record(three_list: list[str]) -> dict[str, str | int] {
    if len(three_list) != 3 {
        raise ValueError('three_list argument did not have three entries');
    }
    (lname, fname, age_str) = three_list;
    if age_str.isdigit() {
        age_int = int(age_str);
    } else {
        raise ValueError('three_list[2] (age_str) should convertible to int');
    }
    return {'last_name': lname, 'first_name': fname, 'age': age_int};
}