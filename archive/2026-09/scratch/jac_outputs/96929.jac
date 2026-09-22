"""Return a string html table of the performance of each element from the last run."""
def performance_info_table(
    channel: int | float, tx: int | float, ctle: int | float, dfe: int | float, jitter: int | float, plotting: int | float, total: int | float
) -> str {
    info_str: str = "<H2>Performance by Component</H2>\n"
    '<TABLE border="1">\n'
    '  <TR align="center">\n'
    "    <TH>Component</TH><TH>Performance (Msmpls./min.)</TH>\n"
    '  </TR>\n  <TR align="right">\n';
    info_str += f'    <TD align="center">Channel</TD><TD>{channel}</TD>\n';
    info_str += '  </TR>\n  <TR align="right">\n';
    info_str += f'    <TD align="center">Tx Preemphasis</TD><TD>{tx}</TD>\n';
    info_str += '  </TR>\n  <TR align="right">\n';
    info_str += f'    <TD align="center">CTLE</TD><TD>{ctle}</TD>\n';
    info_str += '  </TR>\n  <TR align="right">\n';
    info_str += f'    <TD align="center">DFE</TD><TD>{dfe}</TD>\n';
    info_str += '  </TR>\n  <TR align="right">\n';
    info_str += f'    <TD align="center">Jitter Analysis</TD><TD>{jitter}</TD>\n';
    info_str += '  </TR>\n  <TR align="right">\n';
    info_str += f'    <TD align="center">Plotting</TD><TD>{plotting}</TD>\n';
    info_str += '  </TR>\n  <TR align="right">\n';
    info_str += (
        '    <TD align="center"><strong>TOTAL</strong></TD><TD><strong>%6.3f</strong></TD>\n'
        % total
    );
    info_str += "  </TR>\n</TABLE>\n";
    return info_str;
}