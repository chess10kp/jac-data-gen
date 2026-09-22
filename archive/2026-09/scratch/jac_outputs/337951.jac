"""find the next tip on the same contour, encoded in s_values.
	Supposes remaining_id_lst is a sorted list of spiral tip indices,
	Example Usage:
	j_nxt=find_next_tip(remaining_id_lst, s, s_values)
	"""
def find_next_tip(remaining_id_lst: Any, s: Any, s_values: Any) -> object {
    j_nxt = -9999;
    k = 1;
    kmax = len(remaining_id_lst);
    while ((j_nxt < 0) & (k <= kmax)) {
        jj = remaining_id_lst[-k];
        s_nxt = s_values[jj];
        if (s_nxt == s) {
            j_nxt = jj;
        } else {
            k += 1;
        }
    }
    return j_nxt;
}