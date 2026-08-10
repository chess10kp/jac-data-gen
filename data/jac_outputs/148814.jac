"""Extract the passed form data into the self.user_options variable."""
def options_from_form(spawner: Any, formdata: Any) -> object {
    options = {};
    if (formdata.get('is_custom_image', ["off"])[0] == "on") {
        options["image"] = formdata.get('custom_image', [None])[0];
    } else {
        options["image"] = formdata.get('defined_image', [None])[0];
    }
    options["cpu_limit"] = formdata.get('cpu_limit', [None])[0];
    options["mem_limit"] = formdata.get('mem_limit', [None])[0];
    options["is_mount_volume"] = formdata.get('is_mount_volume', ["off"])[0];
    options["days_to_live"] = formdata.get('days_to_live', [None])[0];
    env = {};
    env_lines = formdata.get('env', ['']);
    for line in env_lines[0].splitlines() {
        if line {
            (key, value) = line.split('=', 1);
            env[key.strip()] = value.strip();
        }
    }
    options['env'] = env;
    options['shm_size'] = formdata.get('shm_size', [None])[0];
    options['gpus'] = formdata.get('gpus', [None])[0];
    return options;
}