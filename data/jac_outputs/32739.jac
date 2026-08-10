"""
Function for tracking feedback given in app, updates and reutrns
logger dictionary.
"""
def update_logger(
    image: str,
    model_used: str,
    pred_class: str,
    pred_conf: float,
    correct: bool = False,
    user_label: str | None = None
) -> dict[str, str | float | bool | None] {
    return {
        "image": image,
        "model_used": model_used,
        "pred_class": pred_class,
        "pred_conf": pred_conf,
        "correct": correct,
        "user_label": user_label
    };
}