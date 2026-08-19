def example() {
    n = 42;
    pi = 3.14159265;

    # Integer formats
    f"{n:d}";               # "42" (decimal)
    f"{n:b}";               # "101010" (binary)
    f"{n:o}";               # "52" (octal)
    f"{n:x}";               # "2a" (hex lowercase)
    f"{n:X}";               # "2A" (hex uppercase)
    f"{n:05d}";             # "00042" (zero-padded, width 5)

    # Float formats
    f"{pi:f}";              # "3.141593" (fixed-point, 6 decimals default)
    f"{pi:.2f}";            # "3.14" (2 decimal places)
    f"{pi:10.2f}";          # "      3.14" (width 10, 2 decimals)
    f"{pi:e}";              # "3.141593e+00" (scientific notation)
    f"{pi:.2e}";            # "3.14e+00" (scientific, 2 decimals)
    f"{pi:g}";              # "3.14159" (general format)

    # Percentage
    ratio = 0.756;
    f"{ratio:.1%}";         # "75.6%"

    # Thousands separator
    big = 1234567;
    f"{big:,}";             # "1,234,567"
    f"{big:_}";             # "1_234_567" (underscore separator)
}
