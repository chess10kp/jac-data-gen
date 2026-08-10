"""Create a unique virtual UNI port number based up on PON and ONU ID."""
def mk_uni_port_num(intf_id: int, onu_id: int) -> int {
    return intf_id << 11 | onu_id << 4;
}