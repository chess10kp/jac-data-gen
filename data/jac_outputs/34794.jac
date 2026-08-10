"""
  This function returns the probability of the rule given it's lhs and rhs
  """
def find_prob(lhs: object, rhs: object, rules: list[tuple[object, list[object], float | int]]) -> float | int {
    for rule in rules {
        if len(rule[1]) == 1 and rule[0] == lhs and rhs == rule[1][0] {
            return rule[2];
        }
    }
    return 0;
}