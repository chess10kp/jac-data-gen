"""Reformarts mvnx contacts."""
def get_contacts(contacts: list[dict[str, list]]) -> dict[str, list] {
    left_foot_toe = [];
    right_foot_toe = [];
    left_foot_heel = [];
    right_foot_heel = [];
    for contact in contacts {
        left_foot_heel.append(contact['LeftFoot_Heel'][0]);
        right_foot_heel.append(contact['RightFoot_Heel'][0]);
        left_foot_toe.append(contact['LeftFoot_Toe'][0]);
        right_foot_toe.append(contact['RightFoot_Toe'][0]);
    }
    return {
        'left_heel': left_foot_heel,
        'left_toe': left_foot_toe,
        'right_toe': right_foot_toe,
        'right_heel': right_foot_heel
    };
}