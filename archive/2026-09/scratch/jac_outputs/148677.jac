"""
node01 $  robustness recursion_limit 15
exec_lm_core LM_robustness->recursion_limit: maximum recursion depth exceeded
"""
def recursion_limit(cnt: int = 14, msgobj: Callable[[str], None] | None = None) -> int {
    if cnt > 0 {
        remain = recursion_limit(cnt - 1);
        if msgobj is not None {
            msgobj("recalled {}".format(cnt));
        }
    } else {
        remain = 0;
    }
    return remain;
}