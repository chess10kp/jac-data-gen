"""Use default hyperparameters.

    Parameters
    ----------
    args : dict
        Old configuration

    Returns
    -------
    args : dict
        Updated configuration
    """
def configure(args: Any) -> object {
    configure = {
        'node_hidden_size': 128,
        'num_propagation_rounds': 2,
        'lr': 0.0001,
        'dropout': 0.2,
        'nepochs': 400,
        'batch_size': 1
    };
    args.update(configure);
    return args;
}