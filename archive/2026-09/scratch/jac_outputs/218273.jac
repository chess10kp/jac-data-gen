"""XGboost problem type finder."""
def xgboost_problem_type(hyperparameters: dict[str, str]) -> str {
    try {
        objective = hyperparameters["objective"];
        problem_to_solve = "regression" if objective.startswith("reg") else "classification";
    } except Exception as e {
        print(f"The objective is not defined. The default value is reg:squarederror. Error: {e}");
        problem_to_solve = "regression";
    }
    return problem_to_solve;
}