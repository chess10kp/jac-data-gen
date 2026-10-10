cookbook.jac is basically two dicts of dicts stuffed in a `Kitchen` node that we find with isinstance. can we make it a real graph? recipes and ingredients as nodes, a Needs edge from recipe to ingredient with an optional flag on it, and a one-way swap edge between ingredients. queries should use edge filters, not dict loops.

add_recipe, allow_swap, missing, swaps_needed, cookable and used_in keep the same args and return values.
