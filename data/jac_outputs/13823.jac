import from argparse { Namespace }

"""Returns true if we will need a VM version of our images."""
def _ShouldGenerateVM(options: Namespace) -> bool {
    return options.vm and (options.basic_suite or options.full_suite);
}