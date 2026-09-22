"""
    Check if a string arg is a valid option according to a checklist

    Parameters
    ----------
    parser : argparse object
    arg : str
    checklist

    Returns
    -------
    arg
    """
import from argparse { ArgumentParser }

def is_valid_option(parser: ArgumentParser, arg: str, checklist: list[str]) -> str {
    if not arg in checklist {
        parser.error(
            "'{}' parametised mission type does not exist. Valid options are {}".format(
                arg, checklist
            )
        );
    }
    return arg;
}