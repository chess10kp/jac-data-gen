"""
Used to figure if the npm, pip, gem binary exists in the container image
"""
def binary_does_not_exist(response: str) -> bool {
    return ('executable file not found in' in response
        or 'not found' in response
        or 'no such file or directory' in response);
}