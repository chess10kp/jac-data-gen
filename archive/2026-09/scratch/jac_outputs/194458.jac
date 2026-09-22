""" expand the segment"""
def expand_segment(
    num_frames: Any, num_target_frames: Any, start_frame: Any, stop_frame: Any
) -> object {
    num_frames_seg = (stop_frame - start_frame) + 1;
    changes = False;
    num_target_frames = min(num_target_frames, num_frames);
    if (num_frames_seg < num_target_frames) {
        while True {
            if (start_frame > 0) {
                start_frame -= 1;
                num_frames_seg += 1;
                changes = True;
            }
            if (num_frames_seg == num_target_frames) {
                break;
            }
            if (stop_frame < (num_frames - 1)) {
                stop_frame += 1;
                num_frames_seg += 1;
                changes = True;
            }
            if (num_frames_seg == num_target_frames) {
                break;
            }
        }
    }
    return (start_frame, stop_frame, changes);
}