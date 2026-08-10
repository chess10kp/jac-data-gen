""" Write a SAM tag in the format ``TAG:TYPE:data``
    >>> encode_tag('YM', 'Z', '#""9O"1@!J')
    'YM:Z:#""9O"1@!J'
    """
def encode_tag(tag: str, data_type: str, data: str) -> str {
    ':'.join(list((tag.upper(), data_type.upper(), data)))
}