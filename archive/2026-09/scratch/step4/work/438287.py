def lookup_tlv_type(type_id):
    """Convert TLV type to human readable strings by best guess"""

    result = 'unknown'

    if type_id == 0x01:
        result = 'MAC address'
    elif type_id == 0x02:
        result = 'address'
    elif type_id == 0x03:
        result = 'software'
    elif type_id == 0x06:
        result = 'username'
    elif type_id == 0x07:
        result = 'salt'
    elif type_id == 0x08:
        result = 'challenge'
    elif type_id == 0x0a:
        result = 'uptime'
    elif type_id == 0x0b:
        result = 'hostname'
    elif type_id == 0x0c:
        result = 'model name'
    elif type_id == 0x0d:
        result = 'essid'
    elif type_id == 0x0e:
        result = 'wmode'
    elif type_id == 0x12:
        result = 'counter'
    elif type_id == 0x13:
        result = 'MAC address (UniFi)'
    elif type_id == 0x15:
        result = 'model name (UniFi)'
    elif type_id == 0x16:
        result = 'firmware revision'
    elif type_id == 0x17:
        result = 'unknown (UniFi)'
    elif type_id == 0x18:
        result = 'unknown (UniFi)'
    elif type_id == 0x19:
        result = 'DHCP enabled (UniFi)'
    elif type_id == 0x1b:
        result = 'min firmware (UniFi)'  # ?
    elif type_id == 0x1a:
        result = 'unknown (UniFi)'

    result += ' (' + str(type_id) + ')'

    return result

assert lookup_tlv_type(25) == 'DHCP enabled (UniFi) (25)'
assert lookup_tlv_type(0x03) =='software (3)'
assert lookup_tlv_type(19) == 'MAC address (UniFi) (19)'
assert lookup_tlv_type(1) == 'MAC address (1)'
assert lookup_tlv_type(11) == 'hostname (11)'
assert lookup_tlv_type(26) == 'unknown (UniFi) (26)'
assert lookup_tlv_type(0x16) == 'firmware revision (22)'
assert lookup_tlv_type(0x07) =='salt (7)'
assert lookup_tlv_type(22) == 'firmware revision (22)'
assert lookup_tlv_type(18) == 'counter (18)'
assert lookup_tlv_type(0x17) == 'unknown (UniFi) (23)'
assert lookup_tlv_type(0x0d) == 'essid (13)'
assert lookup_tlv_type(0x12) == 'counter (18)'
assert lookup_tlv_type(3) =='software (3)'
assert lookup_tlv_type(14) == 'wmode (14)'
assert lookup_tlv_type(0x0e) == 'wmode (14)'
assert lookup_tlv_type(0x08) == 'challenge (8)'
assert lookup_tlv_type(23) == 'unknown (UniFi) (23)'
assert lookup_tlv_type(12) =='model name (12)'
assert lookup_tlv_type(0x15) =='model name (UniFi) (21)'
assert lookup_tlv_type(10) == 'uptime (10)'
assert lookup_tlv_type(0x0a) == 'uptime (10)'
assert lookup_tlv_type(24) == 'unknown (UniFi) (24)'
assert lookup_tlv_type(0x13) == 'MAC address (UniFi) (19)'
assert lookup_tlv_type(0x0c) =='model name (12)'
assert lookup_tlv_type(2) == 'address (2)'
assert lookup_tlv_type(0x19) == 'DHCP enabled (UniFi) (25)'
assert lookup_tlv_type(27) =='min firmware (UniFi) (27)'
assert lookup_tlv_type(21) =='model name (UniFi) (21)'
assert lookup_tlv_type(0x01) == 'MAC address (1)'
assert lookup_tlv_type(8) == 'challenge (8)'
assert lookup_tlv_type(0x0b) == 'hostname (11)'
assert lookup_tlv_type(0x06) == 'username (6)'
assert lookup_tlv_type(0x18) == 'unknown (UniFi) (24)'
assert lookup_tlv_type(0x02) == 'address (2)'
assert lookup_tlv_type(13) == 'essid (13)'
assert lookup_tlv_type(6) == 'username (6)'
assert lookup_tlv_type(7) =='salt (7)'
