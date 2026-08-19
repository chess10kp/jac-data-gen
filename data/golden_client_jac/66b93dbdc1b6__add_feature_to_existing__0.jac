if doc.category == self.category_filter {
    doc.summary = summarize(doc.content);
    report ...;
}
