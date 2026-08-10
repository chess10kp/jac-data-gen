""" Returns a filtered list with strings that end with '.pdf'

    Keyword arguments:
    filepaths -- List of filepath strings
    """
def filter_pdf_files(filepaths: Any) -> object {
    return [
        x
        for x in filepaths
        if x.endswith('.pdf')
    ];
}