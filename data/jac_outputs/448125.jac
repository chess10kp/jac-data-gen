"""Get shortcode for the standard date strings, to use in submodel names."""
def get_date_shortcode(date_str: str) -> str {
    match date_str {
        case "std_contest":
            return "SC";
        case "std_contest_daily":
            return "SCD";
        case "std_future":
            return "SF";
        case "std_test":
            return "ST";
        case "std_val":
            return "SV";
        case "std_contest_eval":
            return "SCE";
        case "std_contest_eval_daily":
            return "SCED";
        case "std_paper":
            return "SP";
        case _:
            return date_str;
    }
}