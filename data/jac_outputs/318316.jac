"""Extract the target frame from 2D pose results, and pad the sequence to a fixed length."""
def extract_pose_sequence(
    pose_results: list[list[dict[str, object]]],
    frame_idx: int,
    causal: bool,
    seq_len: int,
    step: int = 1
) -> list[list[dict[str, object]]] {
    if causal {
        frames_left = seq_len - 1;
        frames_right = 0;
    } else {
        frames_left = (seq_len - 1) // 2;
        frames_right = frames_left;
    }
    num_frames = len(pose_results);
    pad_left = max(0, frames_left - frame_idx // step);
    pad_right = max(0, frames_right - (num_frames - 1 - frame_idx) // step);
    start = max(frame_idx % step, frame_idx - frames_left * step);
    end = min(
        num_frames - (num_frames - 1 - frame_idx) % step,
        frame_idx + frames_right * step + 1
    );
    pose_results_seq = (
        [pose_results[0]] * pad_left
        + pose_results[start:end:step]
        + [pose_results[-1]] * pad_right
    );
    return pose_results_seq;
}