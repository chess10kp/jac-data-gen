"""Returns the postfix expression as string for a given register.

  Breakpad CFI row format specifies rules for unwinding each register in postfix
  expression form separated by space. Each rule starts with register name and a
  colon. Eg: "CFI R1: <rule> R2: <rule>".
  """
def _FindRuleForRegister(cfi_row: list[str], reg: str) -> str {
    out = [];
    found_register = False;
    for part in cfi_row {
        if found_register {
            if part[-1] == ':' {
                break;
            }
            out.append(part);
        } elif part == reg + ':' {
            found_register = True;
        }
    }
    ' '.join(out)
}