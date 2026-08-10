"""Get stage label."""
def get_stage_list(n_stages: int, stage_ratios: list[float]) -> list[int] {
    if n_stages == 3 {
        return [0, 1, 2];
    }
    stage_values = [];
    stage = 0;
    threshold = stage_ratios[stage] * n_stages;
    for x in range(n_stages) {
        if x >= threshold {
            stage += 1;
            threshold += stage_ratios[stage] * n_stages;
        }
        stage_values.append(stage);
    }
    return stage_values;
}