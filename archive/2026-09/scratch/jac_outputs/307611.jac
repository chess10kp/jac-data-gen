"""Extract captions from context and map them to more readable names."""
def get_captions(context: dict[str, str]) -> dict[str, str] {
    caption_keys = (
        ('BO_SAVE_CAPTION', 'save_caption'),
        ('BO_SAVE_AS_NEW_CAPTION', 'save_as_new_caption'),
        ('BO_SAVE_AND_CONT_CAPTION', 'save_and_cont_caption'),
        ('BO_SAVE_AND_ADD_ANOTHER_CAPTION', 'save_and_add_another_caption'),
        ('BO_DELETE_CAPTION', 'delete_caption')
    );
    captions = {};
    for (old_key, new_key) in caption_keys {
        captions[new_key] = context.get(old_key, '');
    }
    return captions;
}