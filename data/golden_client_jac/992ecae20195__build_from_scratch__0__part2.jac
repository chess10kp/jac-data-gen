# Default entry - always runs when this module loads
with entry {
    print("Always runs");
}

# Main entry - only runs when this file is executed directly
# Similar to Python's if __name__ == "__main__"
with entry:__main__ {
    print("Only when this file is main");
}
