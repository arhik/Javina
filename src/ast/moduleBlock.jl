struct ModuleBlock <: JLBlock
    #parent::Union{Nothing, ModuleBlock}
    name::Union{Ref{JVVariable}, JLExpr}
    block::Vector{JLExpr}
    scope::Union{Nothing, Scope}
    #child::Vector{ModuleBlock}
end

function moduleBlock(scope::Scope, modname::Symbol, block::Vector{Any})
    #childScope = Scope(Dict(), Dict(), Dict(), scope.depth + 1, scope, :())
    modName = inferExpr(scope, modname)
    exprArray = JLExpr[]
    for jlexpr in block
        push!(exprArray, inferExpr(scope, jlexpr))
    end
    return ModuleBlock(modName, exprArray, scope)
end

#symbol(iff::IfBlock) = (symbol(iff.cond), map(symbol, iff.block)...)
