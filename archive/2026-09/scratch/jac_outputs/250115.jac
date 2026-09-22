"""Formats the user input for a password policy."""
def format_properties(event: dict[str, dict[str, str | int | bool]]) -> dict[str, dict[str, str | int | bool]] {
    event_properties = event["ResourceProperties"];
    allowed_properties_bool = [
        "RequireSymbols",
        "RequireNumbers",
        "RequireUppercaseCharacters",
        "RequireLowercaseCharacters",
        "AllowUsersToChangePassword",
        "HardExpiry"
    ];
    for i in allowed_properties_bool {
        if event_properties[i] == "true" {
            event_properties[i] = True;
        } elif event_properties[i] == "false" {
            event_properties[i] = False;
        } else {
            raise Exception(
                "Resource property values not supported. Values must be boolean."
            );
        }
    }
    allowed_properties_int = [
        "MinimumPasswordLength",
        "MaxPasswordAge",
        "PasswordReusePrevention"
    ];
    for j in allowed_properties_int {
        event_properties[j] = int(event["ResourceProperties"][j] as str);
    }
    return event;
}