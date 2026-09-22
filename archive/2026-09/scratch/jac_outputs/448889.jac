"""
Decodes html encoded emails
Pass a list of emails
Decodes email if starting characters are '&#'
Returns list of unencoded emails
"""
def decrypt(lst: list) -> object {
    while True {
        unencoded_emails = [];
        for string in lst {
            if (string[0:2] == '&#') {
                slices = int((len(string) / 6));
                count = 0;
                starting_pos = 0;
                decoded_email = '';
                while (count < slices) {
                    decoded_email = (
                        decoded_email
                        + chr(int(string[(starting_pos + 2):(starting_pos + 5)]))
                    );
                    count += 1;
                    starting_pos += 6;
                }
                unencoded_emails.append(decoded_email);
            } else {
                unencoded_emails.append(string);
            }
        }
        return unencoded_emails;
    }
}