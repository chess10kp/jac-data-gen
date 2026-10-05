# BeanBot — Jac + SQLite project chatbot
import bootstrap_env;
import domain;
import compliance;
import tasks;
import admin;
import chat;
import beanbot_middleware;

import from .beanbot_client { beanbot_ui }


def:pub app() -> JsxElement {
    return beanbot_ui();
}


with entry {
    import from db { init_db }
    ;
    init_db();
    print(
        "BeanBot ready. Web UI + API: jac start main.jac "
            + "(jac run only initializes the DB and exits.)"
    );
}
