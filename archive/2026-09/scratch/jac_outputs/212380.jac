"""Return full path to kubekins-e2e:tag."""
def kubekins(tag: str) -> str {
    'gcr.io/k8s-testimages/kubekins-e2e:%s' % tag
}