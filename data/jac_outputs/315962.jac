"""Validates a video dictionary JSON from the client."""
def is_video_json_valid(json_payload: dict[str, str]) -> bool {
    if not json_payload["videoUri"] or not json_payload["title"] {
        return False;
    }
    return True;
}