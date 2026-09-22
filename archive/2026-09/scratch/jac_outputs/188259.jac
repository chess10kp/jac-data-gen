"""Returns nodes which fulfill env, roles and virt_roles criteria"""
def filter_nodes(
    nodes: Any, env: Any = '', roles: Any = None, virt_roles: Any = ''
) -> object {
    retval = [];
    if not roles {
        roles = [];
    }
    if virt_roles {
        virt_roles = virt_roles.split(',');
    }
    for `node in nodes {
        append = True;
        if (env and (`node.get('chef_environment', 'none') != env)) {
            append = False;
        }
        if roles {
            if not `set.intersection(
                `set(roles), `set([role.split("_")[0] for role in `node['roles']])
            ) {
                append = False;
            }
        }
        if virt_roles {
            virt_role = `node.get('virtualization', {}).get('role');
            if (
                not (virt_role in virt_roles)
                and not (('guest' in virt_roles) and not virt_role)
            ) {
                append = False;
            }
        }
        if append {
            retval.append(`node);
        }
    }
    return retval;
}