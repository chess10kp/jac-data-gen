glob DEFAULT_KEY = 0xFFFFFFFFFFFFFFFFFFFF;

"""Sets default params for easier testing/input in command line."""
def setDefault(infile: str | None, outfile: str | None, keyfile: str | None, mode: str | None) -> tuple[str, str, int | str, str] {
    plainfile = "Tux.ppm";
    encrypted_file = "Tux_encrypted.ppm";
    decrypted_file = "Tux_decrypted.ppm";
    key: int | str;
    if keyfile {
        key = open(keyfile, 'r').read();
    } else {
        key = DEFAULT_KEY;
    }
    if mode is None {
        print("mode must be 'e' or 'd'");
        exit(1);
    }
    if mode != 'e' and mode != 'd' {
        print("mode must be 'e' or 'd'");
        exit(1);
    }
    if mode == 'e' {
        if infile is None {
            infile = plainfile;
        }
        if outfile is None {
            outfile = encrypted_file;
        }
    }
    if mode == 'd' {
        if infile is None {
            infile = encrypted_file;
        }
        if outfile is None {
            outfile = decrypted_file;
        }
    }
    return (infile as str, outfile as str, key, mode as str);
}