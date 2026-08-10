"""
    Getting folder name from the splitted file_name
    If the file_name is data_FXVOL_20130612.xml, then the folder name returned will be 'FXVOL'
    """
def scrap_middle_name(file: Any) -> object {
    if (
        file.startswith('data_') and file.endswith('.xml') and (file.count('_') == 2)
    ) {
        split_name = file.split('_');
        return split_name[1];
    }
}