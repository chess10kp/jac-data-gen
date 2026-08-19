def _eval(t: any) -> int {
    if isinstance(t, int) {
        return t;
    }
    left = _eval(t["left"]);
    right = _eval(t["right"]);
    match t["op"] {
        case "+":
            return left + right;
        case "-":
            return left - right;
        case "*":
            return left * right;
        case "/":
            return left // right;
        case _:
            raise ValueError(f"unknown op: {t['op']}");
    }
}

def eval_tree(expr: dict) -> str {
    try {
        return f"= {_eval(expr)}";
    } except ZeroDivisionError {
        return "division by zero";
    } except ValueError as e {
        return str(e);
    }
}

with entry {
    print(eval_tree({'op': '+', 'left': {'op': '*', 'left': 3, 'right': 4}, 'right': 5}));
}
