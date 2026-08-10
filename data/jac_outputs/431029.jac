"""Convert arch sampling string to dict mapping epochs to sample counts."""
def arch_sampling_str_to_dict(sampling_str: str) -> dict[float, int] {
    sampling_str = sampling_str.replace(" ", "");
    archs_sampled_list = sampling_str.split(",");
    arch_sampling_dict: dict[float, int] = {};
    for curr_arch_sampling in archs_sampled_list {
        [num_epochs_elapsed, num_archs_to_sample] = curr_arch_sampling.split(":");
        arch_sampling_dict[float(num_epochs_elapsed)] = int(num_archs_to_sample);
    }
    return arch_sampling_dict;
}