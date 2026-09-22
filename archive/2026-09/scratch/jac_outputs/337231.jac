"""
Returns an error message if the schedule is malformed
"""
def _sched_malformed_err(msg: str | None = None) -> str {
    msg = msg if msg else "schedule malformed";
    help_msg = "<br><br>Enter a schedule like <i>r1(x)w1(y)r2(y)r1(z)</i>";
    return msg + help_msg;
}