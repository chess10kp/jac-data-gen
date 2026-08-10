"""
    Converts simple statements of the age at which an agent is born and the
    age at which he dies with certaintiy into the parameters that HARK needs
    for figuring out the timing of the model.

    Parameters
    ----------
    age_birth : int
        Age at which the agent enters the model, e.g., 21.
    age_death : int
        Age at which the agent dies with certainty, e.g., 100.

    Returns
    -------
    dict
        Dictionary with parameters "T_cycle" and "T_age" which HARK expects
        and which map to the birth and death ages specified by the user.

    """
def parse_time_params(age_birth: Any, age_death: Any) -> object {
    T_cycle = age_death - age_birth;
    T_age = (age_death - age_birth) + 1;
    return {"T_cycle": T_cycle, "T_age": T_age};
}