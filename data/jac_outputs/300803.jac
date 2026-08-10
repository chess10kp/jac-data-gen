""" Remove emoticon from tweet (use in pd.df.apply)

    Args:
        entry (entry of pandas df): an entry of the tweet column of the
        tweet dataframe

    Returns:
        output: tweet with emoticon remove
    """
def remove_emoticon(`entry: Any) -> object {
    output = `entry.encode('ascii', 'ignore').decode('ascii');
    return output;
}