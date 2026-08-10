""" parses the tags and repos from a image_results with the format:
{
     'image': [{
           'pluginImage': {
            'ibmContainerRegistry': 'internalRepo/name'
               'publicRegistry': 'repo/name'
           },
              'driverImage': {
                  'ibmContainerRegistry': 'internalRepo/name'
               'publicRegistry': 'repo/name'
          },
               'pluginBuild': 'X.X.X',
               'driverBuild': 'X.X.X',
            'pullPolicy': 'Always'
        }],
       'pluginImage': [{EXACT SAME CONTENTS AS ABOVE}],
    'driverImage': [{EXACT SAME CONTENTS AS ABOVE}]
}

        Current known apps with this format:
            ibm-object-storage-plugin
    """
def parse_both_2(image_results: dict[str, list[dict[str, str | dict[str, str]]]]) -> tuple[list[str], list[str]] {
    tags = [];
    repos = [];
    image_info = image_results['image'][0];
    for (k, v) in image_info.items() {
        if "Build" in k {
            tags.append(v);
        } elif "Image" in k {
            repos.append(v['publicRegistry']);
        }
    }
    return (tags, repos);
}