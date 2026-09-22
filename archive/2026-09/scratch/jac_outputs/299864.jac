"""Re-keys a dict of custom formatters to only use column indices.

  Args:
    formatters: A dict of formatters, keyed by column index or name.
    columns: The list of columns names.

  Returns:
    A dict of formatters keyed only by column index.
  """
def _process_custom_formatters(
    formatters: dict[int | str, Callable[[str], str]],
    columns: list[str]
) -> dict[int, Callable[[str], str]] {
    if not formatters {
        return {};
    }
    column_set = set(columns);
    for col in formatters {
        if isinstance(col, int) and col >= len(columns) {
            print(
                (
                    "Warning: Custom formatter column index %d exceeds total number "
                    "of columns (%d)"
                    % (col, len(columns))
                )
            );
        }
        if not isinstance(col, int) and col not in column_set {
            print(
                (
                    "Warning: Custom formatter column name %s not present in column "
                    "list"
                    % col
                )
            );
        }
    }
    output_formatters = {
        k: v
        for (k, v) in formatters.items()
        if isinstance(k, int)
    };
    for (i, name) in enumerate(columns) {
        if name in formatters {
            if i in output_formatters {
                print(
                    (
                        "Warning: Custom formatter for column index %d present, "
                        "ignoring formatter for column name %s"
                        % (i, name)
                    )
                );
            } else {
                output_formatters[i] = formatters[name];
            }
        }
    }
    return output_formatters;
}