struct FuncBlock <: JLBlock
	fname::Ref{JVVariable}
	fargs::Vector{DeclExpr}
	Targs::Vector{Ref{JVVariable}}
	fbody::Vector{JLExpr}
	scope::Union{Nothing, Scope}
end

function funcBlock(scope::Scope, fname::Symbol, fargs::Vector{Any}, fbody::Vector{Any})
	childScope = Scope(Dict(), Dict(), Dict(), scope.depth+1, scope, quote end)
	fn = inferExpr(scope, fname)
	fa = map(x -> inferExpr(scope, x), fargs)
	fb = map(x -> inferExpr(scope, x), fbody)
	return FuncBlock(fn, fa, JVVariable[], fb, childScope)
end
