"""Evaluates an S_STATEMENT node for variable decleration"""
def S_STATEMENT_VAR_DEC(var: str, eol: str) -> str {
    return var + ";";
}