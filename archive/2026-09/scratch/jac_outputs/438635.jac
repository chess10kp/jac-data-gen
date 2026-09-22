"""
    remove the dashes from a 'yyyy-mm-dd' formatted date
    write as a separate function because the apply(lambda x) one doesn't
    work as expected
    """
def remove_dashes(dashed_date: Any) -> object {
    return str(dashed_date).replace('-', '');
}