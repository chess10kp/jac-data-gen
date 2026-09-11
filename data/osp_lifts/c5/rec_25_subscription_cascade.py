"""Subscription registry with cascading unsubscribe and orphan sweeping.

Subscriptions form a hierarchy: top-level plans own add-on subscriptions,
which may themselves own sub-add-ons. An add-on may be bundled with several
plans (``holders`` = number of live parents). ``unsubscribe`` cancels the
plan and its exclusive descendants; a bundle shared with another live plan
survives. A second, registry-wide sweeper pass cancels any subscription
left with zero holders -- so a shared bundle dies only when its last plan
does. Unknown ids are a silent no-op; re-unsubscribing reports nothing new.
"""


class Subscription:
    def __init__(self, sub_id, plan_name, is_root=False):
        self.sub_id = sub_id
        self.plan_name = plan_name
        self.children = []     # sub_ids of owned add-ons (may be shared out)
        self.holders = 0       # live parents pointing here
        self.is_root = is_root  # top-level plans: never swept as orphans


class SubscriptionRegistry:
    def __init__(self):
        self.subs = {}         # sub_id -> Subscription

    def register(self, sub_id, plan_name, is_root=False):
        sub = Subscription(sub_id, plan_name, is_root=is_root)
        self.subs[sub_id] = sub
        return sub

    def attach(self, parent_id, child_id):
        """Make *child_id* an add-on of *parent_id*."""
        if child_id not in self.subs or parent_id not in self.subs:
            return False       # tolerate unknown refs
        self.subs[parent_id].children.append(child_id)
        self.subs[child_id].holders += 1
        return True

    def _collect(self, sub_id, visited, doomed):
        """Recursive descent over owned children, once-only per id."""
        if sub_id in visited or sub_id not in self.subs:
            return
        visited.add(sub_id)
        doomed.append(sub_id)
        for child_id in self.subs[sub_id].children:
            self._collect(child_id, visited, doomed)

    def unsubscribe(self, sub_id):
        """Cancel *sub_id* plus exclusive descendants, then sweep orphans.

        Returns the sorted list of every subscription removed, including
        orphans picked up by the sweeper. Unknown ids report [].
        """
        if sub_id not in self.subs:
            return []
        doomed = []
        self._collect(sub_id, set(), doomed)
        # dying parents release their holds before removal
        for dead in doomed:
            for child_id in self.subs[dead].children:
                if child_id in self.subs:
                    self.subs[child_id].holders -= 1
        # a doomed sub with a remaining live holder (shared bundle) survives
        removed = []
        for dead in doomed:
            sub = self.subs[dead]
            # the requested id always dies; others need no surviving holder
            if dead == sub_id or sub.is_root or sub.holders <= 0:
                del self.subs[dead]
                removed.append(dead)
        # orphan sweeper: no live holder left and not a top-level plan
        orphans = sorted(
            sid for sid, s in self.subs.items()
            if s.holders <= 0 and not s.is_root
        )
        for sid in orphans:
            del self.subs[sid]
        return sorted(removed + orphans)

    def active(self):
        return sorted(self.subs.keys())

    def is_active(self, sub_id):
        return sub_id in self.subs
