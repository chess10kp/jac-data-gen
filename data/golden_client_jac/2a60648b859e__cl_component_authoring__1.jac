glob _THEME_EVENT: str = "theme-change";

# Dispatch
def dispatchThemeChange(theme: str) -> None {
    evt = new(
        CustomEvent,
        _THEME_EVENT,
        {"detail": {"theme": theme}}
    );
    window.dispatchEvent(evt);
}

# Listen
import from react { useEffect }

def:pub ThemeListener() -> JsxElement {
    has theme: str = "light";

    useEffect(lambda -> None {
        handler = lambda(e: any) {
            theme = e.detail.theme;
        };
        window.addEventListener(_THEME_EVENT, handler);
        return lambda -> None {
            window.removeEventListener(_THEME_EVENT, handler);
        };
    }, []);

    return <div className={theme}>Content</div>;
}
