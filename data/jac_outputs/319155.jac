"""Convert a DFTTK configuration, e.g. [['Fe', 'Ni'], ['Fe']] to ESPEI's configuration [['FE', 'NI'], 'FE']"""
def dfttk_config_to_espei(config: list[list[str]]) -> list[str | list[str]] {
    espei_config = [];
    for subl in config {
        if len(subl) == 1 {
            espei_config.append(subl[0].upper());
        } else {
            espei_config.append([comp.upper() for comp in subl]);
        }
    }
    return espei_config;
}