"""Calculates hamming syndrom"""
def calculateHammingSyndrom(byte: list[int]) -> dict[str, int] {
    S0 = str(
        int(byte[1])
        ^ int(byte[3])
        ^ int(byte[5])
        ^ int(byte[7])
        ^ int(byte[9])
        ^ int(byte[11])
    );
    S1 = str(
        int(byte[2])
        ^ int(byte[3])
        ^ int(byte[6])
        ^ int(byte[7])
        ^ int(byte[10])
        ^ int(byte[11])
    );
    S2 = str(
        int(byte[4]) ^ int(byte[5]) ^ int(byte[6]) ^ int(byte[7]) ^ int(byte[12])
    );
    S3 = str(
        int(byte[8]) ^ int(byte[9]) ^ int(byte[10]) ^ int(byte[11]) ^ int(byte[12])
    );
    SX = str(
        int(byte[0])
        ^ int(byte[1])
        ^ int(byte[2])
        ^ int(byte[3])
        ^ int(byte[4])
        ^ int(byte[5])
        ^ int(byte[6])
        ^ int(byte[7])
        ^ int(byte[8])
        ^ int(byte[9])
        ^ int(byte[10])
        ^ int(byte[11])
        ^ int(byte[12])
    );
    S = int(S3 + S2 + S1 + S0, 2);
    return {"SX": int(SX), "S": S};
}