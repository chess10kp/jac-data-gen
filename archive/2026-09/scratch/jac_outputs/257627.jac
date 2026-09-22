"""
Parses the zone conditions definition YAML files to find the condition
that match both the zone condition passed in.
"""
def getConditionInZoneConditions(
    zone_condition: str,
    zone_conditions_data: dict[str, list[dict[str, str | list[dict[str, object]]]]]
) -> dict[str, str | list[dict[str, str]]] | None {
    condition = {};
    for c in zone_conditions_data['conditions'] {
        if zone_condition != c['name'] {
            continue;
        }
        condition['type'] = c['type'];
        properties = [];
        for p in c['properties'] {
            prop = {};
            prop['property'] = p['property'];
            prop['interface'] = p['interface'];
            prop['path'] = p['path'];
            prop['type'] = p['type'].lower();
            prop['value'] = str(p['value']).lower();
            properties.append(prop);
        }
        condition['properties'] = properties;
        return condition;
    }
}