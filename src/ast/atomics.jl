
# fn atomicAnd(atomic_ptr: ptr<AS, atomic<T>, read_write>, v: T) -> T

struct JVAtomics <: JLExpr
	expr::BinaryOp
end

function atomicExpr(scope::Scope, expr::Expr)
	return JVAtomics(inferExpr(scope, expr))
end
