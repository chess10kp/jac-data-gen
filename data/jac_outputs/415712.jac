"""
    function : Check parameter for initdb
        -D, --pgdata : this has been specified in configuration file
        -W, --pwprompt: this will block the script
        --pwfile: it is not safe to read password from file
        -A, --auth,--auth-local,--auth-host: They will be used with '--pwfile'
        -c, --enpasswd: this will confuse the default password in script
        with the password user specified
        -Z: this has been designated internal
        -U --username: use the user specified during install step
    input  : String
    output : Number
    """
def __checkInitdbParams(param: str) -> int {
    short_invalid_args = ("-D", "-W", "-C", "-A", "-Z", "-U", "-X", "-s");
    long_invalid_args = (
        "--pgdata",
        "--pwprompt",
        "--enpasswd",
        "--pwfile",
        "--auth",
        "--auth-host",
        "--auth-local",
        "--username",
        "--xlogdir",
        "--show"
    );
    arg_list = param.split();
    for arg in short_invalid_args {
        if arg in arg_list {
            return 1;
        }
    }
    arg_list = param.split("=");
    for arg in long_invalid_args {
        if arg in arg_list {
            return 1;
        }
    }
    return 0;
}