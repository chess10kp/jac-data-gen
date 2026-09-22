def single_multiple(status: int) -> str {
    if status & 8 {
        return 'multiple sensors have errors';
    } else {
        return 'only a single sensor has error (or no error)';
    }
}