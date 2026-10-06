import from "@jac/runtime" { Outlet }
import from ..theme { APP_STYLES }


def:pub layout() -> JsxElement {
    return
        <div className="gw-root">
            <style>{APP_STYLES}</style>
            <Outlet/>
        </div>;
}
