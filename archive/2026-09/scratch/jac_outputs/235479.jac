import from argparse { Namespace }

"""Returns true if any conversations were specified on the command line."""
def any_conversations_specified(args: Namespace) -> bool {
    return args.public_channels is not None;
}