"""Return a version of the string escaped for inclusion in an
RFC-822 header, by ensuring there are 8 spaces space after each newline.
"""
def _rfc822_escape(header: str) -> str {
    ('\n' + (8 * ' ')).join(header.split('\n'))
}