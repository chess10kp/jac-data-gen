""" Check for consecutive bytes that repeat once (ex "bb"),
      and that no others have more consecutive bytes
      This function is a prevention of a horrific regex.
  """
def check2(seq: str) -> bool {
    seq = seq.strip(".");
    old = "";
    status = False;
    count = 0;
    for x in seq {
        if x == old {
            count += 1;
        } elif x != old {
            count = 1;
        }
        if count > 2 {
            return False;
        } elif count == 2 {
            status = True;
        }
        old = x;
    }
    return status;
}