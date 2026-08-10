"""Return a number from a string."""
def num_from_str(s: str) -> int | float {
    try {
        return int(s);
    } except ValueError {
        try {
            return float(s);
        } except ValueError {
            raise ValueError(
                ('Can not convert the string "' + s + '" into a numeric value.')
            );
        }
    }
}