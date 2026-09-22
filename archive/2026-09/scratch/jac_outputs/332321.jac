"""filter paraphrase"""
def para_filtering(turn: Any, sentences: Any, K: Any) -> object {
    missing_values = [];
    for (domain_slot, value) in turn["turn_label"] {
        if (
            (value in turn["system_transcript"]) and (value not in turn["transcript"])
        ) {
            missing_values.append(value);
        }
    }
    value_list = [];
    best_sent = "";
    for (domain_slot, value) in turn["turn_label"] {
        (domain, slot) = domain_slot.split("-");
        if (slot == "parking") {
            value = slot;
        } elif (slot == "internet") {
            value = "wifi";
        }
        if (value not in missing_values) {
            value_list.append(value);
        }
    }
    count = 0;
    for sent in sentences {
        sent = sent.lower();
        flag = True;
        for value in value_list {
            if (value not in sent) {
                flag = False;
                break;
            }
        }
        if (flag and (K == count)) {
            best_sent = sent;
            break;
        } elif (flag and (count < K)) {
            count += 1;
        }
    }
    return best_sent;
}