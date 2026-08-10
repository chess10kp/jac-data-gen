"""Helper method does math on operands and returns them"""
def op_help(oper: Any, left_op: Any, right_op: Any) -> object {
    if (oper == '+') {
        return (left_op + right_op);
    } elif (oper == '-') {
        return (left_op - right_op);
    } elif (oper == '*') {
        return (left_op * right_op);
    } else {
        return (left_op / right_op);
    }
}