import type from enum { Enum }

"""
    Converts a list of enums into a delimited string using the enum values
    E.g., [PlayerActionEnum.FLYBALL, PlayerActionEnum.HOMERUN, PlayerActionEnum.WALK] = 'FLYBALL,HOMERUN,WALK'
    """
def convert_enum_list_to_delimited_string(
    enumlist: list[Enum], delimiter: str = ','
) -> str {
    return delimiter.join([listitem.value for listitem in enumlist]);
}