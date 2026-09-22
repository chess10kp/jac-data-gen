"""Make damage list from result; build damage date list from score data."""
def make_damage_list(find_list: list[list[int]], damage: list[str]) -> bool {
    ret = False;
    temp_list: list[int] = [];
    for row in find_list {
        if row[0] != 0 {
            if not temp_list {
                temp_list = row;
                ret = True;
            }
            if row[0] > temp_list[0] + 5 {
                damage.append(str(temp_list[1]));
                temp_list = row;
            } elif row[2] > temp_list[2] {
                temp_list = row;
            }
        }
    }
    if ret {
        damage.append(str(temp_list[1]));
    }
    return ret;
}