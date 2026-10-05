# Alternate entry: same UI as main.jac via beanbot_server includes. Prefer main.jac for day-to-day.
import bootstrap_env;
import beanbot_server;
import from beanbot_entry { beanbot_run_entry }

import from .beanbot_client { beanbot_ui }


def:pub app() -> JsxElement {
    return beanbot_ui();
}


with entry {
    beanbot_run_entry();
}
