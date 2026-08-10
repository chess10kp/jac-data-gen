"""
    epsilon decays as the current episode gets higher because we want the agent to
    explore more in earlier episodes (when it hasn't learned anything)
    explore less in later episodes (when it has learned something)
    i.e. assume that episode number is directly related to learning
    """
def epsilon(current_episode: int, num_episodes: int) -> float {
    0.5 * (0.9 ** current_episode)
}