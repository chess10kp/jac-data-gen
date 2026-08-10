"""Determine if a pipx error message is truly fatal."""
def determine_is_fatal_error(current_error_message: str) -> bool {
    acceptable_error_messages = [
        '(_copy_package_apps:66):   Overwriting file',
        '(_symlink_package_apps:95): Same path'
    ];
    return not any(message in current_error_message for message in acceptable_error_messages);
}