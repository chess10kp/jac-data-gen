def example() {
    default_data = "default";
    file = None;
    data = "";

    try {
        file = open("data.txt");
        data = file.read();
    } except FileNotFoundError {
        print("File not found");
        data = default_data;
    } except PermissionError as e {
        print(f"Permission denied: {e}");
        raise;  # Re-raise the exception
    } else {
        # Executes only if no exception occurred
        print(f"Read {len(data)} bytes");
    } finally {
        # Always executes (cleanup)
        if file {
            file.close();
        }
    }
}
