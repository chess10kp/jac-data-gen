def resolve_data_sink_option(args: dict[str, bool], pipeline: dict[str, bool]) -> bool {
    return args["--rewrite-datasinks"] or pipeline["ds_overwrite"];
}