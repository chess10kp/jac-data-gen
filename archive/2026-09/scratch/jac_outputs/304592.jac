"""
checking whether boxes are lost during the track
"""
def check_object_inconsistent_identifier(frm_list: list[int], tubes: list[dict[int, list[int]]]) -> bool {
    valid_flag = False;
    for (tube_id, tube_info) in enumerate(tubes) {
        if (tube_info[frm_list[0]] != [0, 0, 1, 1]) {
            for tmp_id in range(1, len(frm_list)) {
                tmp_frm = frm_list[tmp_id];
                if (tube_info[tmp_frm] == [0, 0, 1, 1]) {
                    valid_flag = True;
                    return valid_flag;
                }
            }
        }
    }
    return valid_flag;
}