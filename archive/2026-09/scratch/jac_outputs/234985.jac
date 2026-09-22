"""Convert number to IMDB_ID String.

    Args:
        number: number entered

    Returns:
        imdb_id string
    """
def get_imdb_string(number: Any) -> object {
    return 'tt{arg}'.format(arg=str(int(number)).zfill(7));
}