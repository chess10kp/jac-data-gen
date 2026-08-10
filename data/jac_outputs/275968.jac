"""Return a double-quoted string, with all special characters properly escaped."""
def shell_esc(txt: str | int | float | bool) -> str {
  new = str(txt);
  new = new.replace("$", "\\$");
  new = new.replace('"', '\\"');
  new = new.replace('`', '\\`');
  return '"' + new + '"';
}