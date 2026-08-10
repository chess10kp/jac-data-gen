"""
Determine if the combination of the received type, name and version is defined in the <requirement> tag for at least one tool in the received list of tools.
If not, the tool dependency defined by the combination is considered an orphan in it's repository in the tool shed.
"""
def tool_dependency_is_orphan_in_tool_shed(
    `type: str,
    name: str | None,
    version: str | None,
    tools: list[dict[str, list[dict[str, str | None]]]]
) -> bool {
    if tools {
        if `type == 'package' {
            if name and version {
                for tool_dict in tools {
                    requirements = tool_dict.get('requirements', []);
                    for requirement_dict in requirements {
                        req_name = requirement_dict.get('name', None);
                        req_version = requirement_dict.get('version', None);
                        req_type = requirement_dict.get('type', None);
                        if req_name == name and req_version == version and req_type == `type {
                            return False;
                        }
                    }
                }
            }
        } elif `type == 'set_environment' {
            if name {
                for tool_dict in tools {
                    requirements = tool_dict.get('requirements', []);
                    for requirement_dict in requirements {
                        req_name = requirement_dict.get('name', None);
                        req_type = requirement_dict.get('type', None);
                        if req_name == name and req_type == `type {
                            return False;
                        }
                    }
                }
            }
        }
    }
    return True;
}