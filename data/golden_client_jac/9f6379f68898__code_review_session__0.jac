def example() {
    default_data = "default";
    data = "";
    try {
        with open("data.txt") as file {
            data = file.read();
        }
    } except FileNotFoundError {
        print("File not found");
        data = default_data;
    } except PermissionError as e {
        print(f"Permission denied: {e}");
        raise;
    } else {
        print(f"Read {len(data)} bytes");
    }
}
