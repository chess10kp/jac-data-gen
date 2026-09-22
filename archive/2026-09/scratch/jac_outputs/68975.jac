"""Transforms a number representing a mode to a list of flags."""
def _modeToListOfFlags(mode: int) -> list[str] {
    mode_flags = {
        777: 'S_IRWXA',
        700: 'S_IRWXU',
        400: 'S_IRUSR',
        200: 'S_IWUSR',
        100: 'S_IXUSR',
        70: 'S_IRWXG',
        40: 'S_IRGRP',
        20: 'S_IWGRP',
        10: 'S_IXGRP',
        7: 'S_IRWXO',
        4: 'S_IROTH',
        2: 'S_IWOTH',
        1: 'S_IXOTH'
    };
    list_of_flags = [];
    if mode == 777 {
        list_of_flags.append(mode_flags[777]);
    } else {
        mode_string = str(mode);
        entity_position = float(10 ** (len(mode_string) - 1));
        for mode_character in str(mode) {
            try {
                entity = int(mode_character);
            } except ValueError {
                raise Exception("Unexpected mode format: " + str(mode));
            }
            if entity < 0 or entity > 7 {
                raise Exception("Unexpected mode format: " + str(mode));
            }
            if entity == 7 {
                list_of_flags.append(mode_flags[entity * entity_position]);
            } else {
                for flag in mode_flags {
                    if flag > 7 * entity_position or flag < entity_position {
                        continue;
                    }
                    compare = int(str(flag).strip('0'));
                    if (entity & compare) == compare {
                        list_of_flags.append(mode_flags[flag]);
                    }
                }
            }
            entity_position /= 10;
        }
    }
    return list_of_flags;
}