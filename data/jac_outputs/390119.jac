"""Returns a JSON representation of a course cohort settings."""
def _get_course_cohort_settings_representation(
    cohort_id: int, is_cohorted: bool
) -> dict[str, int | bool] {
    {'id': cohort_id, 'is_cohorted': is_cohorted}
}