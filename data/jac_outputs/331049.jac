import from operator { add }
import from functools { reduce }

"""Custom sum function in order to avoid create redundant nodes in Python sum implementation."""
def sum_node_list(node_list: list[int]) -> int {
    return reduce(add, node_list);
}