"""Returns the UserParameters string in a given CodePipeline event data object."""
def get_user_parameters_string(data: dict[str, dict[str, dict[str, str]]]) -> str {
    return data['actionConfiguration']['configuration']['UserParameters'];
}