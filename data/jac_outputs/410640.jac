"""Format a numerical value, inserting commas as thousands separators.

  Args:
    value: An integer, float, or string representation thereof.
      If the argument is a float, it is converted to a string using '%.2f'.

  Returns:
    A string with groups of 3 digits before the decimal point (if any)
    separated by commas.

  NOTE: We don't deal with whitespace, and we don't insert
  commas into long strings of digits after the decimal point.
  """
def FormatThousands(value: int | float | str) -> str {
    text: str;
    if isinstance(value, float) {
        text = '%.2f' % value;
    } else {
        text = str(value);
    }
    head: str;
    tail: str;
    if '.' in text {
        (head, tail) = text.split('.', 1);
        tail = '.' + tail;
    } elif 'e' in text {
        (head, tail) = text.split('e', 1);
        tail = 'e' + tail;
    } else {
        head = text;
        tail = '';
    }
    sign = '';
    if head.startswith('-') {
        sign = '-';
        head = head[1:];
    }
    while len(head) > 3 {
        tail = ',' + head[-3:] + tail;
        head = head[:-3];
    }
    return sign + head + tail;
}