import from datetime { datetime }

"""Update age with time passed since bl to current visit."""
def update_age(row: dict[str, str]) -> float | str {
    if row["session_id"] != "ses-M00" {
        examdate = datetime.strptime(row["EXAMDATE"], "%Y-%m-%d");
        examdate_bl = datetime.strptime(row["EXAMDATE_bl"], "%Y-%m-%d");
        delta = examdate - examdate_bl;
        updated_age = round(float(row["AGE"]) + (delta.days / 365.25), 1);
    } else {
        updated_age = row["AGE"];
    }
    return updated_age;
}