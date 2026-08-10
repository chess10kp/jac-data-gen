"""Find playback_url for video target named 'high', in case there isn't
one, returns the first target on the list. Change this to the specific
target name you wish to play."""
def get_video_play_url(video: dict[str, list[dict[str, str]]]) -> str {
    targets = video['targets'];
    if len(targets) > 0 {
        target = targets[0];
        for t in targets {
            if t['name'] == 'high' {
                target = t;
                break;
            }
        }
        return target['playback_url'];
    }
    return '';
}