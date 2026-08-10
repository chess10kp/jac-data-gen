glob STATUS_UNKNOWN = 0xFF;
glob BIT_CLOSED = 0x01;
glob BIT_CHILD_SAFETY = 0x08;
glob BIT_SECURED_PLUGIN = 0x10;
glob BIT_UNSECURED_PLUGIN = 0x80;
glob BIT_SMART_PLUGIN = 0x01;
glob BIT_BUTTON_PRESSED = 0x80;

"""
Decode a lock status value provided as a hex string (like '0880'),
returning an array of strings representing the parsed bits into
textual described flags.
"""
def get_lock_status_flags(lock_status_value: str) -> list[str] {
    flags = [];
    try {
        status_value = bytearray.fromhex(lock_status_value);
        if not status_value {
            return ['NO-INPUT-ERROR'];
        }
    } except Exception {
        return ['BAD-INPUT-ERROR'];
    }
    if len(status_value) >= 1 {
        if status_value[0] == STATUS_UNKNOWN {
            flags.append('unknown-status');
        } else {
            if status_value[0] & BIT_CLOSED {
                flags.append('closed');
            } else {
                flags.append('open');
            }
            if status_value[0] & BIT_CHILD_SAFETY {
                flags.append('child-safety');
            }
            if status_value[0] & BIT_SECURED_PLUGIN {
                flags.append('secured-plugin');
            }
            if status_value[0] & BIT_UNSECURED_PLUGIN {
                flags.append('unsecured-plugin');
            }
        }
        if len(status_value) >= 2 {
            if status_value[1] == STATUS_UNKNOWN {
                flags.append('unknown-extended');
            } else {
                if status_value[1] & BIT_SMART_PLUGIN {
                    flags.append('smart-plugin');
                }
                if status_value[1] & BIT_BUTTON_PRESSED {
                    flags.append('button-pressed');
                }
            }
        }
    } else {
        flags.append('missing-status-value');
    }
    return flags;
}