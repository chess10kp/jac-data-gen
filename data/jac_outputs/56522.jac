"""
    author:       airbnb_csirt
    description:  Identifies creation of an AMI with a non encrypted volume
    reference:    https://amzn.to/2rQilUn
    playbook:     (a) Reach out to the user who created the volume
                  (b) Re-create the AMI with encryption enabled
                  (c) Delete the old AMI
    """
def unencrypted_ami_volume(rec: dict[str, dict[str, str | dict[str, dict[str, list[dict[str, dict[str, bool | None]]]]] | None]]) -> bool {
    if rec['detail']['eventName'] != 'CreateImage' {
        return False;
    } elif rec['detail']['requestParameters'] is None {
        return False;
    }
    req_params = rec['detail']['requestParameters'] as dict[str, dict[str, list[dict[str, dict[str, bool | None]]]]];
    bdev_map = req_params.get('blockDeviceMapping');
    if bdev_map is None {
        block_device_items = [];
    } else {
        block_device_items = (bdev_map as dict[str, list[dict[str, dict[str, bool | None]]]]).get('items', []);
    }
    if not block_device_items {
        return False;
    }
    volume_encryption_enabled = set();
    for block_device in block_device_items {
        volume_encryption_enabled.add((block_device as dict[str, dict[str, bool | None]]).get('ebs', {}).get('encrypted'));
    }
    return not any(volume_encryption_enabled);
}