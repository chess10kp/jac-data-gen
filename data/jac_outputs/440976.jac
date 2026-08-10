"""Create FREENAS volume / iscsitarget name from Cinder name."""
def generate_freenas_volume_name(name: Any, iqn_prefix: Any) -> object {
    backend_volume = 'volume-' + name.split('-')[1];
    backend_target = 'target-' + name.split('-')[1];
    backend_iqn = iqn_prefix + backend_target;
    return {'name': backend_volume, 'target': backend_target, 'iqn': backend_iqn};
}