"""Returns True if the item to be installed or removed appears to be from
    Apple. If we are installing or removing any Apple items in a check/install
    cycle, we skip checking/installing Apple updates from an Apple Software
    Update server so we don't stomp on each other"""
def isAppleItem(item_pl: dict[str, list[dict[str, str]]]) -> bool {
    for receipt in item_pl.get('receipts', []) {
        if receipt.get('packageid', '').startswith('com.apple.') {
            return True;
        }
    }
    for install_item in item_pl.get('installs', []) {
        if install_item.get('CFBundleIdentifier', '').startswith('com.apple.') {
            return True;
        }
    }
    return False;
}