"""Native LLVM IR generation pass."""

obj Transform {}
obj Module {}
obj Value {}
obj UniNode {}
obj IfStmt(UniNode) {}
obj WhileStmt(UniNode) {}
obj ForStmt(UniNode) {}
obj BinaryExpr(UniNode) {}
obj TupleVal(UniNode) {}

obj NaIRGenPass(Transform) {
    def init(ir_in: Module, prog: object) -> None;
    def transform(ir_in: Module) -> Module;
    def _codegen_body(stmts: (list | tuple)) -> None;
    def _codegen_stmt(nd: UniNode) -> None;
    def _codegen_if(nd: IfStmt) -> None;
    def _codegen_while(nd: WhileStmt) -> None;
    def _codegen_for(nd: ForStmt) -> None;
    def _codegen_expr(nd: (UniNode | None)) -> (Value | None);
    def _codegen_binary(nd: BinaryExpr) -> (Value | None);
    def _codegen_tuple_val(nd: TupleVal) -> (Value | None);
}
