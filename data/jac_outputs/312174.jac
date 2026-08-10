"""Prefixed frame dict should be a dict of base64-encoded files, with prefix."""
def _embedded_checkpoint_frames(prefixed_frame_dict: dict[str, str]) -> str {
    template = '    checkpoint_frames[{0}] = "{1}"\n';
    return "\n" + "".join(
        template.format(i, frame_data.replace('\n', '\\\n'))
        for (i, frame_data) in prefixed_frame_dict.items()
    );
}