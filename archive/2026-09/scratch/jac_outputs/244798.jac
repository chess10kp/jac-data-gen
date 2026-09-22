"""Returns whether the symbol has always been present or not."""
def was_always_present(db_entry: dict[str, int], arches: list[str]) -> bool {
    for arch in arches {
        is_64 = arch.endswith('64');
        introduced_tag = 'introduced-' + arch;
        if introduced_tag not in db_entry {
            return False;
        }
        if is_64 and db_entry[introduced_tag] != 21 {
            return False;
        } elif not is_64 and db_entry[introduced_tag] != 9 {
            return False;
        }
    }
    return True;
}