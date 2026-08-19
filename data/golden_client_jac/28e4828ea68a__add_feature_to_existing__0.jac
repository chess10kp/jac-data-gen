try {
    result = divide(10, 0);
    print(result);
} except ValueError as e {
    print(f"Error: {e}");
} finally {
    print("Done");
}
