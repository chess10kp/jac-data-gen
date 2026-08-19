"""Native LLVM IR generation pass."""

obj NaIRGenPass(Transform) {
    def init(ir_in: uni.Module, prog: object) -> None;
    # Main pass logic
    def transform(ir_in: uni.Module) -> uni.Module;
    # Body / statement codegen
    def _codegen_body(stmts: (list | tuple)) -> None;
    def _codegen_stmt(nd: uni.UniNode) -> None;
    def _codegen_if(nd: uni.IfStmt) -> None;
    def _codegen_while(nd: uni.WhileStmt) -> None;
    # Expression codegen
    def _codegen_expr(nd: (uni.UniNode | None)) -> (ir.Value | None);
    def _codegen_binary(nd: uni.BinaryExpr) -> (ir.Value | None);
    # Phase 9: Tuples
    def _codegen_tuple_val(nd: uni.TupleVal) -> (ir.Value | None);
    # ... 80+ more methods across 16 phases
}
