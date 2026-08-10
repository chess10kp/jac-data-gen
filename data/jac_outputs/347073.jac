"""
    Returns a user by ID.

    :param id:      Id of the user.
    :return:        Dictionary containing the user. 200 if user found. 404 if the user does not exist.
    """
def get(id: int | str) -> dict[str, str | int] {
    {
        "id": id,
        "first_name": "John",
        "last_name": "Smith",
        "profile_image_url": "IMAGE_URL"
    }
}