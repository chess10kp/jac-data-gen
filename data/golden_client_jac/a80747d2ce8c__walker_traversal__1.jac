# api.jac
import from models { User, Todo }

walker get_user {
    can visit with Root entry { report {}; }
}
