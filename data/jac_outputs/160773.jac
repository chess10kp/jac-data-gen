"""
Computes the string representation of a date object composed of "day",
"month", and "year". The argument is a Python dictionary. Example:
{
    "day": "24",
    "month": "September",
    "year" "1985"
}
This would lead to the following output: "24 September 1985".
Empty fields (day, month or year) are ignored. The only allowed date
fields are "day", "month" and "year".

Returns the string representation of the date object.
"""
def serialize_date(date: dict[str, object]) -> str {
    assert set(date.keys()) <= set(["day", "month", "year"]);
    parts = [
        str(value)
        for (_, value) in sorted(date.items())
        if value is not None and len(str(value)) > 0
    ];
    return " ".join(parts);
}