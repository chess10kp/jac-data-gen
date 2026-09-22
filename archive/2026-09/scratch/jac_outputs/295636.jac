"""Convert a one character tcp flag to a three character tcp flag."""
def expand_tcp_flags(flag_code: str) -> str {
    retval = "";
    for character in flag_code {
        match character {
            case "S":
                retval = retval + " SYN";
            case "P":
                retval = retval + " PSH";
            case "F":
                retval = retval + " FIN";
            case "C":
                retval = retval + " CWR";
            case "R":
                retval = retval + " RST";
            case "U":
                retval = retval + " URG";
            case "E":
                retval = retval + " ECE";
            case "A":
                retval = retval + " ACK";
            case _:
                retval = retval=character;
        }
    }
    retval = retval.strip();
    return retval;
}