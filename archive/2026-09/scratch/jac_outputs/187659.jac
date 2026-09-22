""" alters the arguments of calls to calculator methods

  *Not intended for client use*

  This is kind of putrid (and the code ain't so pretty either)
  The general idea is that the various special methods for atomic
  descriptors need two extra arguments (the composition and the atomic
  dict).  Rather than make the user type those in, we just find
  invocations of these methods and fill out the function calls using
  string replacements.
  """
def _SubMethodArgs(cExpr: str, knownMethods: list[str]) -> str {
    res = cExpr;
    for method in knownMethods {
        p = 0;
        while p != -1 and p < len(res) {
            p = res.find(method, p);
            if p != -1 {
                p = p + len(method) + 1;
                start = p;
                paren_count = 1;
                while paren_count and p < len(res) {
                    if res[p] == ')' {
                        paren_count = paren_count - 1;
                    } elif res[p] == '(' {
                        paren_count = paren_count + 1;
                    }
                    p = p + 1;
                }
                if p <= len(res) {
                    res = (
                        res[0:start]
                        + ("'%s',compos,atomDict" % res[start:(p - 1)])
                        + res[(p - 1):]
                    );
                }
            }
        }
    }
    return res;
}