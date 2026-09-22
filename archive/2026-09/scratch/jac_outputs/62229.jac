"""Compute the Bayes factor of the null for each nested model."""
def hp_testing_savage_dickey_ratio(models: dict[str, dict[str, float]]) -> dict[str, float] {
    return {
        model_name: model_dict['posterior'] / model_dict['prior']
        for (model_name, model_dict) in models.items()
    };
}