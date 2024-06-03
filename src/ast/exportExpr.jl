function exportExpr(scope::Scope, name::Symbol)
    scope.globals[name] = makeVarPair(name=>Symbol)
end
