"""Harness: exercise SubscriptionRegistry.unsubscribe, assert post-state."""
from rec_25_subscription_cascade import SubscriptionRegistry


def build():
    """Fixture:

    plan_pro  -> adfree, bundle(shared with plan_basic)
    plan_basic -> bundle
    plan_team -> storage -> storage_plus
    """
    reg = SubscriptionRegistry()
    reg.register("plan_pro", "Pro", is_root=True)
    reg.register("plan_basic", "Basic", is_root=True)
    reg.register("plan_team", "Team", is_root=True)
    reg.register("adfree", "Ad-free")
    reg.register("bundle", "Bundle")
    reg.register("storage", "Storage")
    reg.register("storage_plus", "Storage Plus")
    assert reg.attach("plan_pro", "adfree")
    assert reg.attach("plan_pro", "bundle")
    assert reg.attach("plan_basic", "bundle")   # diamond: shared add-on
    assert reg.attach("plan_team", "storage")
    assert reg.attach("storage", "storage_plus")
    return reg


def test_cancels_plan_and_exclusive_addons():
    reg = build()
    removed = reg.unsubscribe("plan_pro")
    # bundle survives: plan_basic still holds it
    assert removed == ["adfree", "plan_pro"], removed
    assert not reg.is_active("plan_pro")
    assert not reg.is_active("adfree")
    assert reg.is_active("bundle")


def test_shared_bundle_dies_with_last_holder_via_sweeper():
    reg = build()
    _first = reg.unsubscribe("plan_pro")
    second = reg.unsubscribe("plan_basic")
    # the sweeper picks up bundle once its last holder is gone
    assert second == ["bundle", "plan_basic"], second
    assert sorted(reg.active()) == ["plan_team", "storage", "storage_plus"]


def test_deep_chain_and_unknown_ids():
    reg = build()
    assert reg.unsubscribe("ghost") == []
    assert reg.unsubscribe("storage") == ["storage", "storage_plus"]
    assert reg.active() == ["adfree", "bundle", "plan_basic", "plan_pro",
                            "plan_team"]
    # re-unsubscribe reports nothing new
    assert reg.unsubscribe("storage") == []


if __name__ == "__main__":
    test_cancels_plan_and_exclusive_addons()
    test_shared_bundle_dies_with_last_holder_via_sweeper()
    test_deep_chain_and_unknown_ids()
    print("rec_25 ref harness: all assertions passed")
