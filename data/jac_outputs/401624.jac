"""Delete any tags present inside an image"""
def delete_tags(metadata: dict[str, str], key: str) -> int | None {
    try {
        metadata.__delitem__(key);
    } except KeyError {
        print("There's not a %s tag in this image, exiting..." % key);
        return 1;
    }
}