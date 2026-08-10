"""takes in 4-digit years and returns API formatted seasonID."""
def season_id(x: int | str) -> str {
    if len(str(x)) == 4 {
        try {
            return "2" + str(x);
        } except ValueError {
            raise ValueError(
                "Enter the four digit year for the first half of the desired season"
            );
        }
    } else {
        raise ValueError(
            "Enter the four digit year for the first half of the desired season"
        );
    }
}