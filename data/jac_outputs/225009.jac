"""Replace month number by its name."""
def replace_month(json_str: str) -> str {
    json_str = json_str.replace('-01"', '-Ene"');
    json_str = json_str.replace('-02"', '-Feb"');
    json_str = json_str.replace('-03"', '-Mar"');
    json_str = json_str.replace('-04"', '-Abr"');
    json_str = json_str.replace('-05"', '-May"');
    json_str = json_str.replace('-06"', '-Jun"');
    json_str = json_str.replace('-07"', '-Jul"');
    json_str = json_str.replace('-08"', '-Ago"');
    json_str = json_str.replace('-09"', '-Sep"');
    json_str = json_str.replace('-10"', '-Oct"');
    json_str = json_str.replace('-11"', '-Nov"');
    json_str = json_str.replace('-12"', '-Dic"');
    return json_str;
}