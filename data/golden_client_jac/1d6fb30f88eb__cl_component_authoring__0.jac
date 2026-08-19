import from services.recipe {
    ApiResponse, RecipePayload,
    save_profile, list_recipes,
}

cl {
    import ".styles.global.css";
    import from .components.AppShell { AppShell }

    def:pub app() -> JsxElement {
        return <AppShell />;
    }
}
