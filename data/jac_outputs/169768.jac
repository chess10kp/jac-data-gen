"""Adding arguments for the fusion subcommand."""
def get_fusion_options(defaults: dict[str, object] | None = None) -> dict[str, dict[str, object]] {
    if defaults is None {
        defaults = {};
    }
    options = {
        '--fusion-models': {
            "action": 'store',
            "dest": 'fusion_models',
            "default": defaults.get('fusion_models', None),
            "help": "Comma-separated list of models to be included "
            "in the Fusion resource."
        },
        '--fusion-models-file': {
            "action": 'store',
            "dest": 'fusion_models_file',
            "default": defaults.get('fusion_models_file', None),
            "help": "Path to a JSON file that contains a list "
            "of model IDs or maps to include in the "
            "Fusion resource."
        },
        '--fusion': {
            'action': 'store',
            'dest': 'fusion',
            'default': defaults.get('fusion', None),
            'help': "BigML Fusion Id."
        },
        '--fusions': {
            'action': 'store',
            'dest': 'fusions',
            'default': defaults.get('fusions', None),
            'help': "Path to a file containing fusion/ids."
            " One Fusion"
            " per line (e.g., "
            "fusion/50a206a8035d0706dc000376"
            ")."
        },
        '--fusion-file': {
            'action': 'store',
            'dest': 'fusion_file',
            'default': defaults.get('fusion_file', None),
            'help': "BigML Fusion JSON structure file."
        },
        '--fusion-attributes': {
            'action': 'store',
            'dest': 'fusion_attributes',
            'default': defaults.get('fusion_attributes', None),
            'help': "Path to a json file describing Fusion" " attributes."
        }
    };
    return options;
}