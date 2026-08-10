"""Splits a list of args into those for Flags and those for Fire.

  If an isolated '--' arg is not present in the arg list, then all of the args
  are for Fire. If there is an isolated '--', then the args after the final '--'
  are flag args, and the rest of the args are fire args.

  Args:
    args: The list of arguments received by the Fire command.
  Returns:
    A tuple with the Fire args (a list), followed by the Flag args (a list).
  """
def SeparateFlagArgs(args: list[str]) -> tuple[list[str], list[str]] {
    if '--' in args {
        separator_index = len(args) - 1 - args[::-1].index('--');
        flag_args = args[(separator_index + 1):];
        args = args[:separator_index];
        return (args, flag_args);
    }
    return (args, []);
}