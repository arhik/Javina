struct ReturnBlock <: JLBlock
    ret::Union{Ref{JVVariable}, JLExpr, Scalar}
end

function returnBlock(scope::Scope, retExpr::Union{Symbol, Expr})
    return ReturnBlock(inferExpr(scope, retExpr))
end
