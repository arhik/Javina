using CEnum

export JVVariableAttribute

@cenum JVVariableType begin
	Dims
	Global
	Local
	Constant
	Intrinsic
	Generic
	Private
	Uniform
	WorkGroup
	StorageRead
	StorageReadWrite
end

struct JVVariableAttribute
	group::Int
	binding::Int
end

mutable struct JVVariable <: JLVariable
	sym::Symbol
	dataType::Union{DataType, Type}
	varType::JVVariableType
	varAttr::Union{Nothing, JVVariableAttribute}
	mutable::Bool
	undefined::Bool
end

symbol(var::JVVariable) = var.sym
symbol(var::Ref{JVVariable}) = var[].sym

isMutable(var::JVVariable) = var.mutable
isMutable(var::Ref{JVVariable}) = var[].mutable

setMutable!(var::JVVariable, b::Bool) = (var.mutable = b)
setMutable!(varRef::Ref{JVVariable}, b::Bool) = (varRef[].mutable = b)

Base.isequal(var1::JVVariable, var2::JVVariable) = begin
	r = true
	for field in fieldnames(JVVariable)
		r |= getproperty(var1, field) == getproperty(var2, field)
	end
	return r
end
