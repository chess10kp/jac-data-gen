node Step { has label: str; }

walker Logger {
    can start with Root entry {
        visit [-->];  # Begin traversal from root
    }

    can enter with Step entry {
        print(f"ENTER: {here.label}");
        visit [-->];
    }

    can leave with Step exit {
        print(f"EXIT: {here.label}");
    }
}

# Setup: root -> A -> B -> C
# root spawn Logger();
#
# Output:
#   ENTER: A
#   ENTER: B
#   ENTER: C
#   EXIT: C    ← innermost exits first
#   EXIT: B
#   EXIT: A    ← outermost exits last
