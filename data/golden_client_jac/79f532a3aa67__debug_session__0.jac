can with [isLoggedIn] entry {
    if isLoggedIn == prevLoggedIn { return; }
    fetchTasks();
    fetchShoppingList();
}
