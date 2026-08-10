"""Just return how many times Ed answered."""
def count_ed_mgs(db: dict[str, dict[str, int]]) -> int {
    try {
        count = db.get('ed_info')['qty_answed_message'];
    } except Exception {
        count = 1;
    }
    return count;
}