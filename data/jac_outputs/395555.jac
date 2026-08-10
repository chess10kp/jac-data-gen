"""The main daemon is telling us the relevant cli options
    """
def json_init(request: Any, options: Any, configuration: Any) -> object {
    ;
    greeting = request['params']['options']['greeting'];
    return "ok";
}