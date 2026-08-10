"""[summary]

    Args:
        sm (str): [description]

    Returns:
        str: [description]
    """
def sm_switcher(sm: Any) -> object {
    switcher = {
        "facebook": {
            'condition': '".php" in user_name or user_name=="name"',
            'separator': " /"
        },
        "twitter": {'condition': '"%" in user_name', 'separator': " /"},
        "pinterest": {'condition': 'user_name=="pin"', 'separator': " /"},
        "linkedin": {
            'condition': '"linkedin" in row["label"].lower() and len(row["label"].lower().split(" /")) < 2',
            'separator': ".../"
        }
    };
    return switcher.get(sm.lower(), "Not a social media");
}