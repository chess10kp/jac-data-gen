"""Get sequence frame number from sequence settings and current scene frame."""
def sequence_frame_number(
    scene_frame: int, mode: str, start: int, duration: int, offset: int
) -> int | None {
    frame = scene_frame - start + 1;
    match mode {
        case 'CLIP':
            if frame < 1 or frame > duration {
                return None;
            }
        case 'EXTEND':
            frame = min(max(frame, 1), duration);
        case 'REPEAT':
            frame %= duration;
            if frame < 0 {
                frame += duration;
            }
            if frame == 0 {
                frame = duration;
            }
        case _:
            pingpong_duration = duration * 2 - 2;
            frame %= pingpong_duration;
            if frame < 0 {
                frame += pingpong_duration;
            }
            if frame == 0 {
                frame = pingpong_duration;
            }
            if frame > duration {
                frame = duration * 2 - frame;
            }
    }
    frame += offset;
    return frame;
}