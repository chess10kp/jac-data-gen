"""
    This function one hot encodes the input for the event types
    cascade, tracks, doubel-bang, starting tracks
    """
def oneHotEncode_4_evtypes_tau_decay_length_strack_length(
    x: Any, r_vals: Any
) -> object {
    cascade = [1.0, 0.0, 0.0, 0.0];
    track = [0.0, 1.0, 0.0, 0.0];
    doublebang = [0.0, 0.0, 1.0, 0.0];
    s_track = [0.0, 0.0, 0.0, 1.0];
    cut_tau = 5.0;
    cut_track = 75.0;
    if (int(x) in [5, 6]) {
        if (r_vals[8] >= cut_tau) {
            return doublebang;
        } else {
            return cascade;
        }
    } elif (int(x) in [3]) {
        if (r_vals[22] >= cut_track) {
            return s_track;
        } else {
            return cascade;
        }
    } else {
        mapping = {
            0: cascade,
            1: cascade,
            2: track,
            3: s_track,
            4: track,
            5: doublebang,
            6: doublebang,
            7: cascade,
            8: track,
            9: cascade
        };
        return mapping[int(x)];
    }
}