"""Get the instances IDs and names according to nodes dictionary."""
def get_instances_ids_and_names(instances: list) -> dict[str, str] {
    return {
        ('i-' + (instance.get().get('spec').get('providerID').partition('i-')[-1] as str)): instance.get().get(
            'metadata'
        ).get(
            'name'
        ) for instance in instances
    };
}