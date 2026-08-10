"""
    Returns a short portion of the text that shows the first difference
    @ In, a, string, the first text element
    @ In, b, string, the second text element
    @ Out, shortText, string, resulting shortened diff
  """
def shortText(a: object, b: object) -> str {
    a = repr(a);
    b = repr(b);
    display_len = 20;
    half_display = display_len // 2;
    if len(a) + len(b) < display_len {
        return a + " " + b;
    }
    first_diff = -1;
    i = 0;
    while i < len(a) and i < len(b) {
        if a[i] == b[i] {
            i += 1;
        } else {
            first_diff = i;
            break;
        }
    }
    if first_diff >= 0 {
        start = max(0, first_diff - half_display);
    } else {
        first_diff = min(len(a), len(b));
        start = max(0, first_diff - half_display);
    }
    prefix = "..." if start > 0 else "";
    return prefix + a[start:(first_diff + half_display)] + " " + prefix + b[start:(first_diff + half_display)];
}