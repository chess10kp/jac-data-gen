"""
Return weight given an entity grammatical role.
+-----------+--------+
| EGrid Tag | Weight |
+===========+========+
| S         | 3      |
+-----------+--------+
| O         | 2      |
+-----------+--------+
| X         | 1      |
+-----------+--------+
| dash      | 0      |
+-----------+--------+
"""
def weighting_syntactic_role(entity_role: str) -> int {
    match entity_role {
        case "S":
            return 3;
        case "O":
            return 2;
        case "X":
            return 1;
        case _:
            return 0;
    }
}