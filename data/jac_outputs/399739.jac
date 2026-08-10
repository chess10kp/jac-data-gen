"""Right now, this is stupid.

    This will need to be fixed to generate a proper URL to REDcap

    Most likely we'll hit the REDCap db, filter to get a record ID
    and plunk it into the URL."""
def encode_data(name: str, form: str) -> str {
    'https://www.google.com/#q={}'.format(name + form)
}