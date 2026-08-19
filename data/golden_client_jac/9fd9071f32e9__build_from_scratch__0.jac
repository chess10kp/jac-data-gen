can tally with Tweet entry {
    for word in here.content.split() {
        if word.startswith("#") {
            self.counts[word] = self.counts.get(word, 0) + 1;
        }
    }
}
