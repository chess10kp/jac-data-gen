import ".styles.global.css";
import from .frontend { app as ClientApp }


def:pub app() -> JsxElement {
    return <ClientApp/>;
}
