"""
    The subscription message sent to the person requesting pausing or restarting the subscription.

    :param flag: True, means subscription should be made active, False, means subscription should be made inactive.
    None, means there was some error.
    :return: subscription message
    """
def subscription_update_request_feedback(flag: bool | None) -> str {
    if flag is None {
        subscription_message = "We were unable to update your subscription. We are working to fix this up. Sorry, says the Zombie.";
    } elif flag {
        subscription_message = "Welcome back! Your subscription has been restarted. Best of luck answering questions.";
    } else {
        subscription_message = "Your subscription has been paused. \n"
        "For each day your subscription is inactive, you lose 10 karma points";
    }
    return subscription_message;
}