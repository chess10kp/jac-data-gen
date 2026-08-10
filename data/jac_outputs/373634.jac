"""Returns the remote ip-address,
if there is a proxy involved it will take the last IP addres from the HTTP_X_FORWARDED_FOR list
"""
def return_real_remote_addr(env: dict[str, str]) -> str {
    try {
        return env['HTTP_X_FORWARDED_FOR'].split(',')[-1].strip();
    } except KeyError {
        return env['REMOTE_ADDR'];
    }
}