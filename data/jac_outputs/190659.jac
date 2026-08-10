"""Get the interface properties."""
def get_interface_props(props: str) -> str {
    FLAGS = {
        1: "UP",
        2: "BROADCAST",
        4: "LOOPBACK",
        8: "POINTOPOINT",
        16: "MULTICAST",
        32: "RUNNING"
    };
    flag = int(props, 16);
    flag_name = "";
    for bit in FLAGS {
        if flag & bit != 0 {
            flag_name += FLAGS[bit] + "|";
        }
    }
    return flag_name;
}