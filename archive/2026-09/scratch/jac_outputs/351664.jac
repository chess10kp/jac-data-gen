"""Return a string that is the summary of all sweep configurations and averages that ran."""
def sweep_info_table(sweep_results: list[tuple[list[object], float, float]] | None) -> str {
    info_str = "<H2>Sweep Results</H2>\n"
    '<TABLE border="1">\n'
    '  <TR align="center">\n'
    "    <TH>Pretap</TH><TH>Posttap</TH><TH>Mean(bit errors)</TH><TH>StdDev(bit errors)</TH>\n"
    "  </TR>\n";
    if sweep_results {
        for (settings, bit_error_mean, bit_error_std) in sweep_results {
            info_str += '  <TR align="center">\n';
            info_str += f"    <TD>{settings[0]}</TD><TD>{settings[1:]}</TD><TD>{bit_error_mean}</TD><TD>{bit_error_std}</TD>\n";
            info_str += "  </TR>\n";
        }
    }
    info_str += "</TABLE>\n";
    return info_str;
}