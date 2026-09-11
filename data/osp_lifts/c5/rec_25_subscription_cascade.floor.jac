"""Subscription registry with cascading unsubscribe and orphan sweeping.

Subscriptions form a hierarchy: top-level plans own add-on subscriptions,
which may themselves own sub-add-ons. An add-on may be bundled with several
plans (``holders`` = number of live parents). ``unsubscribe`` cancels the
plan and its exclusive descendants; a bundle shared with another live plan
survives. A second, registry-wide sweeper pass cancels any subscription
left with zero holders -- so a shared bundle dies only when its last plan
does. Unknown ids are a silent no-op; re-unsubscribing reports nothing new.
"""
class Subscription {
    def init(
        self: Subscription, sub_id: Any, plan_name: Any, is_root: Any = False
    ) -> object {
        self.sub_id = sub_id;
        self.plan_name = plan_name;
        self.children = [];
        self.holders = 0;
        self.is_root = is_root;
    }
}
class SubscriptionRegistry {
    def init(self: SubscriptionRegistry) -> object {
        self.subs = {};
    }
    def register(
        self: SubscriptionRegistry, sub_id: Any, plan_name: Any, is_root: Any = False
    ) -> object {
        sub = Subscription(sub_id, plan_name, is_root=is_root);
        self.subs[sub_id] = sub;
        return sub;
    }
    def attach(self: SubscriptionRegistry, parent_id: Any, child_id: Any) -> object {
        if ((child_id not in self.subs) or (parent_id not in self.subs)) {
            return False;
        }
        self.subs[parent_id].children.append(child_id);
        self.subs[child_id].holders += 1;
        return True;
    }
    def _collect(
        self: SubscriptionRegistry, sub_id: str, visited: set[str],
        doomed: list[str]
    ) -> object {
        if ((sub_id in visited) or (sub_id not in self.subs)) {
            return;
        }
        visited.add(sub_id);
        doomed.append(sub_id);
        kids = self.subs[sub_id].children as list[str];
        for child_id in kids {
            self._collect(child_id, visited, doomed);
        }
    }
    def unsubscribe(self: SubscriptionRegistry, sub_id: str) -> object {
        if (sub_id not in self.subs) {
            return [];
        }
        doomed: list[str] = [];
        self._collect(sub_id, set(), doomed);
        for dead in doomed {
            for child_id in self.subs[dead].children {
                if (child_id in self.subs) {
                    self.subs[child_id].holders -= 1;
                }
            }
        }
        removed = [];
        for dead in doomed {
            sub = self.subs[dead];
            if ((dead == sub_id) or sub.is_root or (sub.holders <= 0)) {
                delete(self.subs[dead],);
                removed.append(dead);
            }
        }
        orphans = sorted(
            sid
            for (sid, s) in self.subs.items()
            if ((s.holders <= 0) and not s.is_root)
        );
        for sid in orphans {
            delete(self.subs[sid],);
        }
        return sorted((removed + orphans));
    }

    def active(self: SubscriptionRegistry) -> object {
        return sorted(self.subs.keys());
    }
    def is_active(self: SubscriptionRegistry, sub_id: Any) -> object {
        return (sub_id in self.subs);
    }
}

