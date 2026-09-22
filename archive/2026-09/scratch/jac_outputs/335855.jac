"""Compute raw token length and encoded targets length for random_spans_noise_mask training."""
def compute_input_and_target_lengths(
    inputs_length: int, noise_density: float, mean_noise_span_length: float
) -> tuple[int, int] {
    def _tokens_length_to_inputs_length_targets_length(tokens_length: int) -> tuple[int, int] {
        num_noise_tokens = int(round(tokens_length * noise_density));
        num_nonnoise_tokens = tokens_length - num_noise_tokens;
        num_noise_spans = int(round(num_noise_tokens / mean_noise_span_length));
        input_length = num_nonnoise_tokens + num_noise_spans + 1;
        output_length = num_noise_tokens + num_noise_spans + 1;
        return (input_length, output_length);
    }
    tokens_length = inputs_length;
    while _tokens_length_to_inputs_length_targets_length(tokens_length + 1)[0] <= inputs_length {
        tokens_length += 1;
    }
    (inputs_length, targets_length) = _tokens_length_to_inputs_length_targets_length(tokens_length);
    if noise_density == 0.5 and targets_length > inputs_length {
        tokens_length -= 1;
        targets_length -= 1;
    }
    return (tokens_length, targets_length);
}