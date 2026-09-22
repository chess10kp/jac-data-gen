"""Returns a human readable form of the cpp type."""
def cpp_type_name(type_as_str: str) -> str {
    types = {
        'uint8_t': 'UInt8',
        'uint16_t': 'UInt16',
        'uint32_t': 'UInt32',
        'uint64_t': 'UInt64',
        'int8_t': 'Int8',
        'int16_t': 'Int16',
        'int32_t': 'Int32',
        'int64_t': 'Int64',
        'bool': 'Boolean',
        'float': 'FloatingPoint32',
        'double': 'FloatingPoint64',
        'const char *': 'UTF8String',
        'nl::SerializedByteString': 'ByteString'
    };
    return types.setdefault(type_as_str, 'Structure');
}