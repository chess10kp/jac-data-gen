"""Convert yes/no answer to True/False."""
def yesno_to_bool(s: str) -> bool {
  return s in ("y", "yes");
}