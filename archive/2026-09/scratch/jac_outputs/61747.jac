"""
    Intermediate top reward.
    """
def calcTopReward(top_action: Any, gold_labels: Any) -> object {
    lenth = len(top_action);
    r = [0.0 for i in range(lenth)];
    rem = [0 for i in range(len(gold_labels))];
    for i in range(lenth)[::-1] {
        if (top_action[i] > 0) {
            ok = -1;
            for (j, label) in enumerate(gold_labels) {
                if (label['type'] == top_action[i]) {
                    if (rem[j] == 0) {
                        ok = 1;
                        rem[j] = 1;
                        break;
                    } else {
                        ok = -0.2;
                    }
                }
            }
            r[i] = ok;
        }
    }
    return r;
}