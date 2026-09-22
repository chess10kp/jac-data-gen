"""Extracts the id of the submission referenced by the usernote"""
def get_id_of_referenced_submission(user_note: Any) -> object {
    link_code_segments = user_note['l'].split(',');
    if (len(link_code_segments) > 1) {
        return link_code_segments[1];
    } else {
        return None;
    }
}