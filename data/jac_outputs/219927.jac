"""Computes the run identifier for the given learning rates. Search identifier will not contain w_eval.

    Args:
        lrs (dict): That that contains the learning rate for every searched learning rate.

    Returns:
        str: String that uniquely represents a run with the given learning rates.
    """
def get_lr_run_identifier(lrs: dict[str, float]) -> str {
    run_identifier = "";
    for val in ['w_search', 'alpha', 'beta'] {
        try {
            run_identifier += f"{val}-{lrs[val]}_";
        } except KeyError {
            break;
        }
    }
    if 'w_eval' in lrs {
        run_identifier += f"w_eval-{lrs['w_eval']}_";
    }
    run_identifier = run_identifier[:-1];
    return run_identifier;
}