"""
    If your Active Directory schema does not natively support Unix account attributes
    and a schema extension is not possible, Safeguard Authentication Services uses "schemaless"
    functionality where Unix account information is stored in the altSecurityIdentities attribute.
    Examples of group_object in schemaless mode:
    {
        "DistinguishedName": "CN=tg-1974,CN=Users,DC=d16,DC=sb",
        "Name": "tg-1974",
        "ObjectClass": "group",
        "ObjectGUID": "ee3b40d7-3419-45cc-8778-d90fd798ae2d",
        "altSecurityIdentities": [
            "X509:<S>CN=Posix Group<I>CN=Quest Software<DATA>GroupName: tg-1974",
            "X509:<S>CN=Posix Group<I>CN=Quest Software<DATA>GroupGidNumber: 8135"
        ]
    },
    {
        "DistinguishedName": "CN=tg-1993,CN=Users,DC=d16,DC=sb",
        "Name": "tg-1993",
        "ObjectClass": "group",
        "ObjectGUID": "1a7de3d9-d8ff-477b-8498-05ce330f9e11",
        "altSecurityIdentities": [
            "X509:<S>CN=Posix Group<I>CN=Quest Software<DATA>GroupName: tg-1993",
            "X509:<S>CN=Posix Group<I>CN=Quest Software<DATA>GroupGidNumber: 8136"
        ]
    }
    """
def extract_properties_when_schemaless(group_objects_list: Any) -> object {
    attrs = ['GroupName', 'GroupGidNumber'];
    groups = [];
    for group_object in group_objects_list {
        group = [];
        for attr in attrs {
            alt_sec_ids = group_object['altSecurityIdentities'];
            for alt_sec_id in alt_sec_ids {
                label = 'X509:<S>CN=Posix Group<I>CN=Quest Software<DATA>' + attr + ':';
                if (label in alt_sec_id) {
                    group.append(alt_sec_id[len(label):].strip());
                    break;
                }
            } else {
                group.append('');
            }
        }
        if (group[0] and group[1]) {
            dn = 'DistinguishedName';
            if ((dn in group_object) and group_object[dn]) {
                group.insert(0, group_object[dn]);
            } else {
                group.insert(0, '');
            }
            groups.append(group);
        }
    }
    return groups;
}