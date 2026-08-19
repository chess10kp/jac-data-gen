walker:priv ClearCompletedTasks {
    can prune with Task entry { if here.done { del here; } }
}
