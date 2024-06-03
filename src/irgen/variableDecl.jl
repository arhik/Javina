
export PrivateVar, @var, @letvar

using Infiltrator
using Lazy:@forward

struct ImplicitPadding
	decl::Pair{Symbol, DataType}
end

struct StructEndPadding
	decl::Pair{Symbol, DataType}
end

export jvType

abstract type Atomic end
abstract type Zeroable end
abstract type StorableType end
abstract type Constructible end
abstract type Variable end

struct VarAttribute
	group::Int
	binding::Int
end

jvType(attr::VarAttribute) = begin
	return "@group($(attr.group)) @binding($(attr.binding)) "
end

function getEnumJVVariableType(s::Symbol)
	ins = instances(JVVariableType)
	for i in ins
		if string(s) == string(i)
			return i
		end
	end
	@error "Var type $s is not known. You might have to define it"
end

jvType(a::Val{getEnumJVVariableType(:Generic)}) = string()
jvType(a::Val{getEnumJVVariableType(:Private)}) = "<private>"

struct VarDataType{T} <: Variable
	attribute::Union{Nothing, VarAttribute}
	valTypePair::Pair{Symbol, eltype(T)}
	value::Union{Nothing, eltype(T)}
	varType::JVVariableType
end

struct LetDataType{T} <: Variable
	valTypePair::Pair{Symbol, eltype(T)}
	value::Union{Nothing, eltype(T)}
end

# TODO compose VarDataType and LetDataType sometime later

attribute(var::VarDataType{T}) where T = begin
	return var.attribute
end

valueType(var::VarDataType{T}) where T = begin
	return var.valueType
end

value(var::VarDataType{T}) where T = begin
	return var.value
end

varType(var::VarDataType{T}) where T = begin
	return var.varType
end

jvType(var::VarDataType{T}) where T = begin
	attrStr = let t = var.attribute; t == nothing ? "" : jvType(t) end
	varStr = "var$(jvType(Val(var.varType))) $(jvType(var.valTypePair))"
	valStr = let t = var.value; t == nothing ? "" : "= $(jvType(t))" end
	return "$(attrStr)$(varStr) $(valStr);\n"
end

jvType(letvar::LetDataType{T}) where T = begin
	letStr = "let $(jvType(letvar.valTypePair))"
	t = letvar.value
	valStr = ""
	if @capture(t, SMatrix{N_, M_, TT_, L_}(a__))
		@assert length(a) == N*M "Matrix dimensions should match input length: But found {$N, $M} and {$L} instead!!!"
		valStr = "= $(jvType(t))"
	elseif @capture(t, SVector{N_, TT_, L_}(a__))
		@assert length(a) == N "Matrix dimensions should match input length: But found {$N} and {$L} instead!!!"
		valStr = "= $(jvType(t))"
	else
		valStr = let t = letvar.value; t === nothing ? "" : "= $(jvType(t))" end
	end
	@assert valStr != "" "Let var should be defined ..."
	return "$(letStr) $(valStr);\n"
end

struct GenericVar{T} <: Variable
	var::VarDataType{T}
end

function GenericVar(
	pair::Pair{Symbol, T},
	group::Union{Nothing, Int},
	binding::Union{Nothing, Int},
	value::eltype(T)
) where T
	attrType = Union{map(typeof, [group, binding])...}
	@assert attrType in [Nothing, Int] "Both group and binding should be defined or left to nothing"
	VarDataType{T}(
		(attrType == Nothing) ? nothing : VarAttribute(group, binding),
		pair,
		value,
		getEnumJVVariableType(:Generic)
	)
end

@forward GenericVar.var attribute, valueType, value, Base.getproperty, Base.setproperty!


struct PrivateVar{T} <: Variable
	var::VarDataType{T}
end

function PrivateVar(
	pair::Pair{Symbol, T},
	group::Union{Nothing, Int},
	binding::Union{Nothing, Int},
	value::eltype(T)
) where T
	attrType = Union{map(typeof, [group, binding])...}
	@assert attrType in [Nothing, Int] "Both group and binding should be defined or left to nothing"
	VarDataType{T}(
		attrType == Nothing ? nothing : VarAttribute(group, binding),
		pair,
		value,
		getEnumJVVariableType(:Private)
	)
end

@forward PrivateVar.var attribute, valueType, value, Base.getproperty, Base.setproperty!


function defineVar(
	varType::Symbol,
	pair::Pair{Symbol, T},
	group::Union{Nothing, Int},
	binding::Union{Nothing, Int},
	value::eltype(T)
) where T
	attrType = Union{map(typeof, [group, binding])...}
	@assert attrType in [Nothing, Int] "Both group and binding should be defined or left to nothing"
	VarDataType{T}(
		attrType == Nothing ? nothing : VarAttribute(group, binding),
		pair,
		value,
		getEnumJVVariableType(varType)
	)
end


function defineLet(
	pair::Pair{Symbol, T},
	value::eltype(T)
) where T
	LetDataType{T}(
		pair,
		value,
	)
end


macro var(dtype::Expr)
	@capture(dtype, a_::dt_) && return defineVar(:Generic, a=>(dt |> eval), nothing, nothing, nothing)
	@capture(dtype, a_::dt_ = v_) && return defineVar(:Generic, a=>(dt |> eval), nothing, nothing, v)
	@capture(dtype, a_ = v_) && return defineVar(:Generic, a=>:Any, nothing, nothing, v)
	@error "Unexpected Var expression !!!"
end

macro var(vtype, dtype::Expr)
	@capture(dtype, a_::dt_) || @error "Expecting sym::dtype! Current args are: $vtype, $dtype"
	defineVar(vtype, a=>(eval(dt)), nothing, nothing, nothing)
end

macro var(vtype::Symbol, group::Int, binding::Int, dtype::Expr)
	@capture(dtype, a_::dt_) || @error "Expecting sym::dtype!"
	defineVar(vtype, a=>(eval(dt)), group, binding, nothing)
end

macro var(vtype::Symbol, group::Int, binding::Int, dtype::Expr, value)
	@capture(dtype, a_::dt_) || @error "Expecting sym::dtype!"
	defineVar(vtype, a=>(eval(dt)), group, binding, value)
end

macro var(vtype::Symbol, dtype::Expr, value)
	@capture(dtype, a_::dt_) || @error "Expecting sym::dtype!"
	defineVar(vtype, a=>(eval(dt)), nothing, nothing, value)
end

macro letvar(dtype::Expr) # TODO type must be checked most likely
	@capture(dtype, a_::dt_ = v_) &&  return defineLet(a=>(eval(dt)), v)
	@capture(dtype, a_::dt_) && return defineLet(a=>(eval(dt)), nothing)
	@capture(dtype, a_=v_) && return defineLet(a=>:Any, v)
	@error "Expecting @let sym::dtype value!"
end

macro letvar(dtype::Expr, value::Any) # TODO type must be checked most likely
	@capture(dtype, a_::dt_) && return defineLet(a=>(eval(dt)), value)
	@error "Expecting @let sym::dtype value!"
end


macro letvar(dtype::Symbol, value::Any) # TODO type must be checked most likely
	# @capture(dtype, a_) &&  return defineLet(a=>eval(dt), value)
	@error "Not sure if this is allowed!!! Expecting @let sym value!"
end
