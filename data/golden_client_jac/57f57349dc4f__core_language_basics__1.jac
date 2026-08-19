# compute.na.jac
import from "libm" {
    def sin(x: f64) -> f64;
    def cos(x: f64) -> f64;
    def sqrt(x: f64) -> f64;
}

with entry {
    result = sqrt(sin(1.0) ** 2 + cos(1.0) ** 2);
    print(result);  # 1.0
}
