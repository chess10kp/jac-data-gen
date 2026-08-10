"""
  Escape all DN special characters found in s
  with a back-slash (see RFC 4514, section 2.4)
  """
def escape_dn_chars(s: str) -> str {
    if s {
        s = s.replace('\\', '\\\\');
        s = s.replace(',', '\\,');
        s = s.replace('+', '\\+');
        s = s.replace('"', '\\"');
        s = s.replace('<', '\\<');
        s = s.replace('>', '\\>');
        s = s.replace(';', '\\;');
        s = s.replace('=', '\\=');
        s = s.replace('\000', '\\\000');
        if s[0] in ('#', ' ') {
            s = ''.join(('\\', s));
        }
        if s[-1] == ' ' {
            s = ''.join((s[:-1], '\\ '));
        }
    }
    return s;
}