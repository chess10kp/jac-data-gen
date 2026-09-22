"""If banned return True else False."""
def bann(code: str) -> bool {
    ban_list = [
        'First Ride',
        'New Customers',
        'From SMU',
        'From NTU',
        'From NUS',
        'From SUTD',
        'From SIM',
        'First GrabHitch',
        'New GrabPay',
        'First 2 Rides',
        'First 4 Rides'
    ];
    for word in ban_list {
        if code.find(word) > 0 {
            return True;
        }
    }
    return False;
}