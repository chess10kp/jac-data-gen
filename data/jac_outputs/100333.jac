import from textwrap { wrap }

glob LOGGER_LINE_WIDTH = 75;
glob LOGGER_INDENT_SIZE = 13;

"""Prettifies logger messages by breaking them up into multi lines"""
def prettify_logger_message(msg: str) -> str {
    linewidth = LOGGER_LINE_WIDTH - LOGGER_INDENT_SIZE;
    indent = "\n" + (" " * LOGGER_INDENT_SIZE);
    temp = wrap(msg, width=linewidth);
    return indent.join(temp);
}