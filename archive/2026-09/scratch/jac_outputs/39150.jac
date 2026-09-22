"""Replace the ori_str to corresponding mode in mode_dict"""
def _encodeMode(ori_str: str, mode_dict: dict[str, str]) -> str {
    for (mode, value) in mode_dict.items() {
        ori_str = ori_str.replace(mode, value);
    }
    return ori_str.strip(",");
}