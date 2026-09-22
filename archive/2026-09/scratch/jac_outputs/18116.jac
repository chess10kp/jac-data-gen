"""Get padding and out padding for deconv layers."""
def _get_deconv_pad_outpad(deconv_kernel: int) -> tuple[int, int, int] {
    match deconv_kernel {
        case 4:
            padding = 1;
            output_padding = 0;
        case 3:
            padding = 1;
            output_padding = 1;
        case 2:
            padding = 0;
            output_padding = 0;
        case _:
            raise ValueError(f"Not supported num_kernels ({deconv_kernel}).");
    }
    return (deconv_kernel, padding, output_padding);
}