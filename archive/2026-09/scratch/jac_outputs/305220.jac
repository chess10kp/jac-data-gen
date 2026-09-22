""" format optional Config.in string, like
    if (((cond1 || cond2) && cond3) || (cond4 || cond5))
    source $AOS_SDK_PATH/core/cli/Config.in
    endif
    condition_list is [[cond1, cond2, and cond3], [cond4, cond5]]
    config_file is filename of Config.in
    """
def get_comp_optional_depends_text(conditions_list: list[list[str]], config_file: str) -> tuple[str, str] {
    line = "if (";
    conds_line = "";
    for conds in conditions_list {
        conds_line += "(";
        cond_line = "";
        for cond in conds {
            if cond == "and" {
                cond_line = "(" + cond_line[:-4] + ") && ";
            } else {
                cond_line += "%s || " % cond;
            }
        }
        conds_line += cond_line[:-4];
        conds_line += ") || ";
    }
    conds_line = conds_line[:-4];
    line += conds_line;
    line += ")\n" + ('source "$AOS_SDK_PATH/%s"\n' % config_file) + "endif\n";
    return (line, conds_line);
}