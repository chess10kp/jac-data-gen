"""Converts the legacy ACL format to an IAM Policy proto."""
def convert_acl_to_iam_policy(acl: Any) -> object {
    owners = acl.get('owners', []);
    readers = acl.get('readers', []);
    if acl.get('all_users_can_read', False) {
        readers.append('allUsers');
    }
    writers = acl.get('writers', []);
    bindings = [];
    if owners {
        bindings.append({'role': 'roles/owner', 'members': owners});
    }
    if readers {
        bindings.append({'role': 'roles/viewer', 'members': readers});
    }
    if writers {
        bindings.append({'role': 'roles/editor', 'members': writers});
    }
    return {'bindings': bindings};
}