"""Check the validity of an AFM number (Greek VAT code).

  Check if input is a valid AFM number via its check digit (not if it is actually used).
  Return either True of False.
  Input should be given as a string. An integer, under certain conditions, could through an exception.
  """
def check_afm(afm: str) -> bool {
    if not isinstance(afm, str) {
        raise TypeError(
            "check_afm()",
            "You should feed to this function only strings to avoid exceptions and errors! Aborting."
        );
    }
    if len(afm) == 11 and afm[:2].upper() == "EL" {
        afm = afm[2:];
    }
    if afm.isdigit() == True and len(afm) == 9 {
        (i, sums) = (256.0, 0.0);
        for digit in afm[:-1] {
            sums += int(digit) * i;
            i /= 2;
        }
        checksum = sums % 11;
        if int(afm[-1]) == int(checksum) or (checksum == 10 and afm[-1] == "0") {
            return True;
        }
    }
    return False;
}