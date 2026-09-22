"""Convert a zerocoded bytestring into a bytestring"""
def decode(bytedata: bytes) -> bytes {
    i = 0;
    l = len(bytedata);
    while i < l {
        if bytedata[i] == 0 {
            c = bytedata[i + 1] - 1;
            bytedata = bytedata[:i + 1] + (b'\x00' * c) + bytedata[i + 2:];
            i = i + c;
            l = l + c - 1;
        }
        i = i + 1;
    }
    return bytedata;
}