"""Return an example Java class with content_to_add contained within a method."""
def setup_java_class(content_to_add: str) -> str {
    template = """
public class Lambda {

    public static void main(String args[]) {
        %s
    }
}
        """;
    return template % content_to_add;
}