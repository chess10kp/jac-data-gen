"""Process metadata function."""
def tumor_type_match(section: list[dict[str, str]], keywords: list[str], match_type: str) -> list[dict[str, str]] {
    for d in section {
        if not keywords {
            d[match_type] = "null";
        } else {
            d[match_type] = "False";
        }
        for k in keywords {
            if k in d["db_tumor_repr"].lower() {
                d[match_type] = "True";
                break;
            }
        }
    }
    return section;
}