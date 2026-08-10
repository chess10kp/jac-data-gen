"""change any number to word number. """
def remove_number(s: str) -> str {
    try {
        float(s);
        return "number";
    } except ValueError {
        try {
            int(s);
            return "number";
        } except ValueError {
            return s;
        }
    }
}