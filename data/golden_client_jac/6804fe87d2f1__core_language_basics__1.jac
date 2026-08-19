def example() {
    name = "Alice";
    # Width specification
    f"{name:10}";           # "Alice     " (10 chars, left-aligned)
    f"{name:>10}";          # "     Alice" (right-aligned)
    f"{name:^10}";          # "  Alice   " (centered)
    f"{name:<10}";          # "Alice     " (left-aligned, explicit)

    # Fill character
    f"{name:*>10}";         # "*****Alice" (fill with *)
    f"{name:-^10}";         # "--Alice---" (centered with -)
}
