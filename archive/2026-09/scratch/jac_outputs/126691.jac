import re;

"""
    "(SO3)2" -> ("(SO3)2", "(SO3)", "2")
    "(SO3)" -> ("(SO3)", "(SO3)", "")
    """
def get_sub_formula(formula: str) -> tuple[str, str, str] | None {
    `match = re.search('(\([a-zA-Z\d]+\))(\d*)', formula);
    if not `match {
        return;
    }
    return (`match.group(0), `match.group(1), `match.group(2));
}