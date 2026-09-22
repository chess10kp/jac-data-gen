"""
Constructs a CTL formula that queries whether for every variables v specified in *Names* there is a path to a state x in which v is unsteady.

Typically this query is used to find out if the variables given in *Names* are oscillating in a given attractor.
"""
def EF_unsteady_states(Names: list[str]) -> str {
    Names = [x for x in Names if x.strip()];
    if Names == [] {
        return 'TRUE';
    }
    return ' & '.join([('EF(!%s_STEADY)' % x) for x in Names]);
}