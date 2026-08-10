"""Remove punctuation from data."""
def remove_punctuation(data: str) -> str {
    try {
        if data[-1:] == ',' {
            data = data[:-1];
        }
        if data[-2:] == ' :' {
            data = data[:-2];
        }
        if data[-2:] == ' ;' {
            data = data[:-2];
        }
        if data[-2:] == ' /' {
            data = data[:-2];
        }
        if data[-2:] == ' -' {
            data = data[:-2];
        }
    } except Exception {
        ;
    }
    return data;
}