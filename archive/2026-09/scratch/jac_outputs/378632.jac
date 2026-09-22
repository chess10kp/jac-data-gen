"""Read the fuzzer setting from the list of dict."""
def get_fuzzer_setting(fuzzer_settings: Any, fuzzer_setting_name: Any) -> object {
    for fuzzer_setting in fuzzer_settings {
        if (
            ("Name" in fuzzer_setting)
            and (fuzzer_setting["Name"] == fuzzer_setting_name)
        ) {
            return fuzzer_setting;
        }
    }
    return None;
}