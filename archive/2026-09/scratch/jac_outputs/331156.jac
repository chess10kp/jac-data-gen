"""formats a profile image to match what will be in JSON"""
def format_image_expectation(profile: dict[str, str]) -> dict[str, str] {
    image_fields = ['image', 'image_medium', 'image_small'];
    for field in image_fields {
        if field in profile {
            profile[field] = "http://testserver{}".format(profile[field]);
        }
    }
    return profile;
}