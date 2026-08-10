"""Create a usable config from the wandb config format."""
def from_wandb_format(config: dict[str, dict | str | int | float | bool | list | None]) -> dict[str, dict | str | int | float | bool | list | None] {
    wandb_config = {};
    for (key, value) in config.items() {
        if '.' in key {
            sub_keys = key.split('.');
            curr_dict = wandb_config;
            for sub_key in sub_keys[:-1] {
                if sub_key not in curr_dict {
                    curr_dict[sub_key] = {};
                }
                curr_dict = curr_dict[sub_key];
            }
            if isinstance(value, dict) and 'value' in value {
                curr_dict[sub_keys[-1]] = value['value'];
            } else {
                curr_dict[sub_keys[-1]] = value;
            }
        } elif isinstance(value, dict) and 'value' in value {
            wandb_config[key] = value['value'];
        } else {
            wandb_config[key] = value;
        }
    }
    return wandb_config;
}