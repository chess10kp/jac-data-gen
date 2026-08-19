can act with Tweet entry {
    if self.actor in here.likes {
        here.likes.remove(self.actor);
        report {"liked": False};
    } else {
        here.likes.append(self.actor);
        report {"liked": True};
    }
}
