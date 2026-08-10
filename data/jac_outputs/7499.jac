"""Helper function to satisfy argparse.ArgumentParser.add_argument()'s
input argument syntax."""
def argument(*name_or_flags: str, **kwargs: str | int | bool) -> tuple[list[str], dict[str, str | int | bool]] {
    return (list(name_or_flags), kwargs);
}