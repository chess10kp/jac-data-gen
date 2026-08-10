glob CRC32_POLY = 0xedb88320;
glob INT31_MASK = 0x7FFFFFFF;

"""Combine two CRC-32 checksums."""
def crc32_combine(crc1: int, crc2: int, len2: int) -> int {
    if len2 <= 0 {
        return crc1;
    }
    odd = [CRC32_POLY] + [1 << i for i in range(0, 31)];
    even = [0] * 32;
    def matrix_times(matrix: list[int], vector: int) -> int {
        number_sum = 0;
        matrix_index = 0;
        while vector != 0 {
            if vector & 1 {
                number_sum ^= matrix[matrix_index];
            }
            vector = (vector >> 1) & INT31_MASK;
            matrix_index += 1;
        }
        return number_sum;
    }
    even[:] = [matrix_times(odd, odd[n]) for n in range(0, 32)];
    odd[:] = [matrix_times(even, even[n]) for n in range(0, 32)];
    while len2 != 0 {
        even[:] = [matrix_times(odd, odd[n]) for n in range(0, 32)];
        if len2 & 1 {
            crc1 = matrix_times(even, crc1);
        }
        len2 >>= 1;
        if len2 == 0 {
            break;
        }
        odd[:] = [matrix_times(even, even[n]) for n in range(0, 32)];
        if len2 & 1 {
            crc1 = matrix_times(odd, crc1);
        }
        len2 >>= 1;
    }
    crc1 ^= crc2;
    return crc1;
}