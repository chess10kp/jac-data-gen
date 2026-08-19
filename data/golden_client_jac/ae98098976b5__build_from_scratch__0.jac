can deliver with Root exit {
    self.log.append("traversal complete");
    report GraphSnapshot(nodes=self.nodes, edges=self.edges, path=self.path, log=self.log);
}
