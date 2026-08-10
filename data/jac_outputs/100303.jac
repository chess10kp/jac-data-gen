"""Evaluates CRRA marginal marginal utility of consumption c given risk aversion gam."""
def CRRAutilityPP(c: float, gam: float) -> float {
    -gam * (c ** (-gam - 1.0))
}