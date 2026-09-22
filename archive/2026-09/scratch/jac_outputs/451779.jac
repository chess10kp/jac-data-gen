"""Returns the number of leading zeros in a float decimal."""
def __get_leading_zeros(fl: Any) -> object {
    if (fl > 1.0) {
        return 0;
    } else {
        fl_splitted = str(fl).split(".")[-1];
        N_unstripped = len(fl_splitted);
        N_left_stripped = len(fl_splitted.lstrip("0"));
        return (N_unstripped - N_left_stripped);
    }
}