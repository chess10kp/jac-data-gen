"""
Returns True if the user has provided all of the required registration info

Args:
    user (django.contrib.auth.models.User):

Returns:
    bool: True if the user has provided all of the required registration info
"""
def is_user_info_complete(user: object) -> bool {
    return (
        hasattr(user, "profile")
        and getattr(user, "profile").is_complete
        and hasattr(user, "legal_address")
        and getattr(user, "legal_address").is_complete
    );
}