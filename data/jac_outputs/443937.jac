"""Converting the string that describes the environment id into an int which needed for the http request."""
def convert_environment_id_string_to_int(environment_id: str) -> int {
    try {
        environment_id_options = {
            "300: Linux Ubuntu 16.04": 300,
            "200: Android (static analysis)": 200,
            "160: Windows 10": 160,
            "110: Windows 7": 110,
            "100: Windows 7": 100,
            "64-bit": 64,
            "32-bit": 32
        };
        return environment_id_options[environment_id];
    } except Exception {
        raise Exception('Invalid environment id option');
    }
}