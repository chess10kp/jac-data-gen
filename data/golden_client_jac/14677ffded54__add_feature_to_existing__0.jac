test "unfollowing stops a user's tweets from propagating to the feed" {
    client = make_client();
    client.register_user("alice", "secret123");
    client.register_user("bob", "secret123");

    client.login("bob", "secret123");
    bob_profile = first_report(
        client.post("/walker/setup_profile", json={"username": "bob"})
    );
    client.post("/walker/create_tweet", json={"content": "bob's update"});
    bob_id = jid_of(bob_profile["profile"]);

    client.login("alice", "secret123");
    client.post("/walker/setup_profile", json={"username": "alice"});
    client.post("/walker/follow_user", json={"target_id": bob_id});

    feed_following = first_report(client.post("/walker/load_feed", json={}));
    assert any(t["content"] == "bob's update" for t in feed_following);

    client.post("/walker/unfollow_user", json={"target_id": bob_id});
    assert not any(t["content"] == "bob's update" for t in feed_following);

    client.close();
}
