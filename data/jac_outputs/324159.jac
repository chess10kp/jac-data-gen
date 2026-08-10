"""Obtains the TFDS D4RL name."""
def _d4rl_dataset_name(env_name: str) -> str {
    split_name = env_name.split('-');
    task = split_name[0];
    version = split_name[-1];
    level = '-'.join(split_name[1:-1]);
    return f'd4rl_adroit_{task}/{version}-{level}';
}