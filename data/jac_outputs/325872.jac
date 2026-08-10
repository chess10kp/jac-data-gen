"""Default value generator for pandas._testing.makeCustomDataframe."""
def make_dataframe_value(nrows: int, ncols: int) -> str {
    f"R{nrows}C{ncols}"
}