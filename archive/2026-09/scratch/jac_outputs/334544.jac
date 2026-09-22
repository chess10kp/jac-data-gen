"""
Converts a string into a bool using the following sets:
  True: ['true', '1', 't', 'y', 'yes']
  False: ['false', '0', 'f', 'n', 'no']
Throws ValueError s is neither None nor in either true or false value set.
"""
def strToBool(s: str | None) -> bool {
    if s {
        lowered = s.lower();
        if lowered in ['true', '1', 't', 'y', 'yes'] {
            return True;
        } elif lowered in ['false', '0', 'f', 'n', 'no'] {
            return False;
        } else {
            raise ValueError;
        }
    } else {
        return False;
    }
}