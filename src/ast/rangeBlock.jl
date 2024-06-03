struct RangeBlock <: JLBlock
	start::Union{Ref{JVVariable}, JLExpr, Scalar}
	step::Union{Ref{JVVariable}, JLExpr, Scalar}
	stop::Union{Ref{JVVariable}, JLExpr, Scalar}
	idx::Union{JLExpr}
	block::Vector{JLExpr}
	scope::Union{Nothing, Scope}
end

struct RangeExpr <: JLExpr
	start::Union{Ref{JVVariable}, JLExpr, Scalar}
	step::Union{Ref{JVVariable}, JLExpr, Scalar}
	stop::Union{Ref{JVVariable}, JLExpr, Scalar}
end

function inferExpr(scope::Scope, range::StepRangeLen)
	@error "Not implemented yet"
end

function rangeBlock(scope::Scope, idx::Symbol, range::Expr, block::Vector{Any})
	# TODO deal with StepRangeLen also may be ? I don't see its use though.
	childScope = Scope(Dict(), Dict(), Dict(), scope.depth + 1, scope, :())
	rangeExpr = inferRange(childScope, range)
	startExpr = rangeExpr.start
	if typeof(startExpr) == Ref{JVVariable}
		childScope.globals[symbol(startExpr)] = startExpr[].sym
	end
  	stopExpr =  rangeExpr.stop
	if typeof(stopExpr) == Ref{JVVariable}
		childScope.globals[symbol(stopExpr)] = stopExpr[].sym
	end
	stepExpr = rangeExpr.step
	if typeof(stepExpr) == Ref{JVVariable}
		childScope.globals[symbol(stepExpr)] = stepExpr[].sym
	end
	idxExpr = inferExpr(childScope, :($idx::UInt32))
	setMutable!(idxExpr, true)
	scope.globals[idx] = idxExpr.sym[]
	exprArray = JLExpr[]
	for stmnt in block
		push!(exprArray, inferExpr(childScope, stmnt))
	end
	rangeBlockExpr = RangeBlock(startExpr, stepExpr, stopExpr, idxExpr, exprArray, childScope)
end
