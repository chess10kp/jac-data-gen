"""Convert an int to attack label string."""
def index2string(index: int) -> str {
    match index {
        case 0:
            string = 'BENIGN';
        case 1:
            string = 'FTP-Patator';
        case 2:
            string = 'SSH-Patator';
        case 3:
            string = 'DoS Hulk';
        case 4:
            string = 'DoS GoldenEye';
        case 5:
            string = 'DoS slowloris';
        case 6:
            string = 'DoS Slowhttptest';
        case 7:
            string = 'Heartbleed';
        case 8:
            string = 'Web Attack Brute Force';
        case 9:
            string = 'Web Attack XSS';
        case 10:
            string = 'Web Attack Sql Injection';
        case 11:
            string = 'Infiltration';
        case 12:
            string = 'Bot';
        case 13:
            string = 'PortScan';
        case 14:
            string = 'DDoS';
        case _:
            print("[ERROR] Cannot convert {}".format(index));
            string = 'Error';
    }
    return string;
}