"""
Scale bytes to its proper format
e.g:
    1253656 => '1.20MB'
    1253656678 => '1.17GB'
"""
def get_size(bytes: int | float, suffix: str = "B") -> str | None {
    factor = 1024;
    for unit in ["", "K", "M", "G", "T", "P"] {
        if bytes < factor {
            return f"{bytes:.2f}{unit}{suffix}";
        }
        bytes /= factor;
    }
}