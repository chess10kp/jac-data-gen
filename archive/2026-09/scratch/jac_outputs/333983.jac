"""Calculate number of environment frames in a batch of experience."""
def num_env_steps(infos: list[dict[str, int]]) -> int {
    total_num_frames = 0;
    for info in infos {
        total_num_frames += info.get('num_frames', 1);
    }
    return total_num_frames;
}