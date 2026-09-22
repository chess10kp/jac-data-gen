"""error_max_retry message"""
def error_max_retry(num_retries: int, err_string: str) -> str {
    return "Unable to retrieve artifact after {} retries: {}".format(num_retries, err_string);
}