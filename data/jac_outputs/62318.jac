"""Ref: https://github.com/facebookresearch/CovidPrognosis/blob/master/cp_examples/sip_finetune/sip_finetune.py"""
def fix_mocov2_state_dict(state_dict: dict[str, object]) -> dict[str, object] {
    new_state_dict = {};
    for (k, v) in state_dict.items() {
        if k.startswith("model.encoder_q.") {
            k = k.replace("model.encoder_q.", "");
            new_state_dict[k] = v;
        }
    }
    return new_state_dict;
}