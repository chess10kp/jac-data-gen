"""For the given event_list, determine whether physical
    or spell offensive actions take place"""
def check_timestamp_event_type(event_list: Any) -> object {
    for line in event_list {
        if (
            ('You perform' in line)
            or ('You attack ' in line)
            or ('You shot' in line)
            or ('You miss' in line)
            or ('You fumble' in line)
            or ('evades your attack' in line)
        ) {
            return 'physical';
        } elif (
            ('you cast' in line)
            or ('You hit' in line)
            or ('resists the effect' in line)
        ) {
            return 'spell';
        }
    }
    return 'no-op';
}