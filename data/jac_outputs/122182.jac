"""split simple molname"""
def split_simple(molname_simple: str) -> tuple[list[str | None], list[str]] {
    atom_list = [];
    num_list: list[str] = [];
    tmp: str | None = None;
    num = "";
    for ch in molname_simple {
        if ch.isupper() {
            if tmp is not None {
                atom_list.append(tmp);
                num_list.append(num);
                num = "";
            }
            tmp = ch;
        } elif ch.islower() {
            tmp = (tmp as str) + ch;
        } elif ch.isdigit() {
            num = ch;
        }
    }
    atom_list.append(tmp);
    num_list.append(num);
    return (atom_list, num_list);
}