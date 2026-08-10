"""Checks that the sequence of served_order is first-come, first-served"""
def check_cake_order_sequence(
    take_out: list[str],
    dine_in: list[str],
    served_orders: list[str]
) -> bool {
    take_out_index = 0;
    dine_in_index = 0;
    for order in served_orders {
        if take_out[take_out_index] == order {
            take_out_index += 1;
        } elif dine_in[dine_in_index] == order {
            dine_in_index += 1;
        } else {
            return False;
        }
    }
    return True;
}