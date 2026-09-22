"""Wrap a URL string."""
def wrap_url(s: str, l: int) -> str {
    parts = s.split('/');
    if len(parts) == 1 {
        return parts[0];
    }
    i = 0;
    lines = [];
    for j in range(i, len(parts) + 1) {
        tv = '/'.join(parts[i:j]);
        nv = '/'.join(parts[i:j + 1]);
        if len(nv) > l or nv == tv {
            i = j;
            lines.append(tv);
        }
    }
    return '/\n'.join(lines);
}