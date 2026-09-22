""" Create a schedule with a step decrease preceded by a warmup
        period during which the learning rate increases linearly between {lr_start} and {lr_max}.
    """
def step_schedule_with_warmup(
    step: int,
    step_size: int,
    warmup_steps: int = 0,
    hold_max_steps: int = 0,
    lr_start: float = 0.0001,
    lr_max: float = 0.001,
    step_decay: float = 0.5
) -> float {
    if step < warmup_steps {
        lr = (lr_max - lr_start) / warmup_steps * step + lr_start;
    } elif step < warmup_steps + hold_max_steps {
        lr = lr_max;
    } else {
        lr = lr_max * (step_decay ** ((step - warmup_steps - hold_max_steps) // step_size));
    }
    return lr;
}