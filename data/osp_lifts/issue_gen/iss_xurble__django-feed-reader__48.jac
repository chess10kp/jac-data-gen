# iss_xurble__django-feed-reader__48.jac

node User {
    has id: str;
}

node Subscription {
    has id: str;
    has user_id: str;
    has is_folder: bool = False;
    has posts: list[str] = [];
}

edge Owns {}
edge ParentOf {}

obj FeedStore {
    has users: dict[str, User] = {};
    has subscriptions: dict[str, Subscription] = {};
}

walker SubtreeWalk {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];
    has posts: list[str] = [];
    has owner: str = "";

    can step with Subscription entry {
        print(here.id);
        if here.id in self.claimed {
            skip;
        }
        self.claimed[here.id] = True;
        if here.user_id != self.owner {
            skip;
        }
        self.found.append(here.id);
        for post in here.posts {
            self.posts.append(post);
        }
        for kid in [here ->:ParentOf:->][?:Subscription] {
            visit :0: [kid];
        }
    }
}

walker UserUnreadWalk {
    has claimed: dict[str, bool] = {};
    has ids: list[str] = [];
    has owner: str = "";

    can step_user with User entry {
        print(here.id);
        if here.id != self.owner {
            skip;
        }
        for sub in [here ->:Owns:->][?:Subscription] {
            visit :0: [sub];
        }
    }

    can step_subscription with Subscription entry {
        print(here.id);
        if here.id in self.claimed {
            skip;
        }
        self.claimed[here.id] = True;
        if here.user_id != self.owner {
            skip;
        }
        if len(here.posts) > 0 {
            self.ids.append(here.id);
        }
        for kid in [here ->:ParentOf:->][?:Subscription] {
            visit :0: [kid];
        }
    }
}

def lookup(store: FeedStore, sid: str) -> Subscription | None {
    if sid in store.subscriptions {
        return store.subscriptions[sid];
    }
    return None;
}

def create_subscription(
    store: FeedStore,
    sid: str,
    user_id: str,
    is_folder: bool = False,
    posts: list[str] | None = None
) -> Subscription {
    if sid in store.subscriptions {
        return store.subscriptions[sid];
    }
    if user_id not in store.users {
        user = User(id=user_id);
        store.users[user_id] = user;
    }
    post_list: list[str] = [];
    if posts is not None {
        for post in posts {
            post_list.append(post);
        }
    }
    sub = Subscription(
        id=sid,
        user_id=user_id,
        is_folder=is_folder,
        posts=post_list
    );
    store.subscriptions[sid] = sub;
    user = store.users[user_id];
    user +>:Owns:+> sub;
    return sub;
}

def set_parent(store: FeedStore, child_id: str, parent_id: str) -> bool {
    child = lookup(store, child_id);
    parent = lookup(store, parent_id);
    if child is None or parent is None {
        return False;
    }
    if child.id == parent.id {
        return False;
    }
    if parent.is_folder is not True or child.user_id != parent.user_id {
        return False;
    }
    for old_parent in [child <-:ParentOf:<-][?:Subscription] {
        if old_parent.id == parent.id {
            return True;
        }
        return False;
    }
    w = parent spawn SubtreeWalk(claimed={}, owner=child.user_id);
    if child.id in w.found {
        return False;
    }
    parent +>:ParentOf:+> child;
    return True;
}

def unread_count(store: FeedStore, sid: str) -> int {
    sub = lookup(store, sid);
    if sub is None {
        return 0;
    }
    w = sub spawn SubtreeWalk(claimed={}, owner=sub.user_id);
    return len(w.posts);
}

def get_unread_posts(store: FeedStore, sid: str) -> list[str] {
    sub = lookup(store, sid);
    result: list[str] = [];
    if sub is None {
        return result;
    }
    w = sub spawn SubtreeWalk(claimed={}, owner=sub.user_id);
    return sorted(w.posts);
}

def get_paginated_posts(
    store: FeedStore,
    sid: str,
    page: int,
    page_size: int
) -> list[str] {
    result: list[str] = [];
    if page < 1 or page_size < 1 {
        return result;
    }
    all_posts: list[str] = get_unread_posts(store, sid);
    start: int = (page - 1) * page_size;
    stop: int = start + page_size;
    for i in range(len(all_posts)) {
        if i >= start and i < stop {
            result.append(all_posts[i]);
        }
    }
    return result;
}

def mark_read(store: FeedStore, sid: str) -> int {
    sub = lookup(store, sid);
    if sub is None {
        return 0;
    }
    w = sub spawn SubtreeWalk(claimed={}, owner=sub.user_id);
    marked: int = len(w.posts);
    for found_id in w.found {
        target = lookup(store, found_id);
        if target is not None {
            target.posts = [];
        }
    }
    return marked;
}

def get_unread_subscription_list_for_user(
    store: FeedStore,
    user_id: str
) -> list[Subscription] {
    result: list[Subscription] = [];
    if user_id not in store.users {
        return result;
    }
    user = store.users[user_id];
    w = user spawn UserUnreadWalk(claimed={}, owner=user_id);
    for sid in sorted(w.ids) {
        target = lookup(store, sid);
        if target is not None {
            result.append(target);
        }
    }
    return result;
}
