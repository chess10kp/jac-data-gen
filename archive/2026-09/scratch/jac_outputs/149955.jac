"""Extracts appscale-datastore server port from command line arguments."""
def port_from_datastore_start_cmd(args: list[str]) -> int {
    if len(args) < 2 or not args[1].endswith('appscale-datastore') {
        raise ValueError('Not a datastore start command');
    }
    return int(args[args.index('--port') + 1]);
}