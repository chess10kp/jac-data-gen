"""parses the command-line flags and options passed to the script"""
def parseopts(opts: list[tuple[str, str]]) -> dict[str, str | int] {
    params = {};
    for (opt, arg) in opts {
        match opt {
            case "-K":
                params['K'] = int(arg);
            case "--input":
                params['inputfile'] = arg;
            case "--output":
                params['outputfile'] = arg;
            case "--popfile":
                params['popfile'] = arg;
            case "--title":
                params['title'] = arg;
        }
    }
    return params;
}