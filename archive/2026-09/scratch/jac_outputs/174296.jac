"""Extracts only emails from below structure and returns them as list
    data = [
        {
            ...: ...,
            'Attributes': [
                {
                    'Name': 'email'
                    'Value': '...'
                },
                ...
            ],
        },
        {
            ...
        }
    ]

    Args:
        data (List): List of objects representing user in Cognito

    Returns:
        List: List of emails
    """
def get_emails(data: Any) -> object {
    emails = [];
    for item in data {
        email = [
            i['Value']
            for i in item['Attributes']
            if (i['Name'] == 'email')
        ][0];
        emails.append(email);
    }
    return emails;
}