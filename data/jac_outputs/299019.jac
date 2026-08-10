"""Given the target type, return the list of TARGET_TAGS to parameterize Freedom E SDK"""
def type2tag(target_type: str) -> str {
    if "arty" in target_type or "vc707" in target_type or "vcu118" in target_type {
        tags = "fpga openocd";
    } elif "hifive1-revb" in target_type {
        tags = "board jlink";
    } elif "rtl" in target_type {
        tags = "rtl";
    } elif "spike" in target_type {
        tags = "spike";
    } elif "qemu" in target_type {
        tags = "qemu";
    } else {
        tags = "board openocd";
    }
    return tags;
}