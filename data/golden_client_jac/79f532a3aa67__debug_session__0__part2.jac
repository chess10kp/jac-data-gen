cl {
    sv import from .main { fetchTasks, fetchShoppingList }

    def:pub Dashboard(isLoggedIn: bool) -> JsxElement {
        can with [isLoggedIn] entry {
            if isLoggedIn {
                fetchTasks();
                fetchShoppingList();
            }
        }

        return <div>Dashboard</div>;
    }
}
