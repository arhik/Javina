using StaticArrays
using Infiltrator

varyingTypes = [
	"f32", "vec2<f32>", "vec3<f32>", "vec4<f32>",
	"i32", "vec2<i32>", "vec3<i32>", "vec4<i32>",
	"u32", "vec2<u32>", "vec3<u32>", "vec4<u32>"
]

juliaToJVTypes = Dict(
	Char => "ub",
	Bool => "b",
	Int16 => "h",
	UInt16 => "h",
	Int32 => "w",
	Int64 => "l",
	UInt32 => "w",
	UInt64 => "l",
	Float16 => "h",
	Float32 => "s",
	Float64 => "d",
)

jvType(a::Bool) = a;
jvType(a::Int32) = "$(a)i";
jvType(a::UInt32) = "$(a)u";
jvType(a::Float16) = "$(a)"; #TODO refer to jv specs and update this
jvType(a::Float32) = "$(a)";
jvType(a::Int) = a;
jvType(a::Number) = a;

function jvType(::Type{Vec2{T}}) where {T}
	return "vec2<$(jvType(T))>"
end

function jvType(::Type{Vec3{T}}) where {T}
	return "vec3<$(jvType(T))>"
end

function jvType(::Type{Vec4{T}}) where {T}
	return "vec4<$(jvType(T))>"
end

function jvType(t::Type{T}) where T
	jvtype = get(juliaToJVTypes, T, nothing)
	if jvtype === nothing
		@error "Invalid Julia type $T with value $t or missing jv type"
	end
	return jvtype
end

function jvType(::Type{Mat4{T}}) where T
 	return "mat4x4<$(jvType(T))>"
end

function jvType(::Type{Mat3{T}}) where T
 	return "mat3x3<$(jvType(T))>"
end

function jvType(::Type{Mat2{T}}) where T
 	return "mat2x2<$(jvType(T))>"
end

function jvType(::Type{Array{T, N}}) where {T, N}
	return "array<$(jvType(T)), $N>"
end

function jvType(::Type{Array{T}}) where T
	return "array<$(jvType(T))>"
end

function jvType(a::Function)
	return nameof(a)
end

function jvType(::Type{SMatrix{N, M, T, L}}) where {N, M, T, L}
	return "mat$(N)x$(M)<$(jvType(T))>"
end

function jvType(::Type{SVector{N, T}}) where {N, T}
	return "vec$(N)<$(jvType(T))>"
end

function jvType(a::Pair{Symbol, DataType})
	return "$(jvType(a.second)) %$(a.first) "
end

function jvType(a::Pair{Symbol, Any})
	if a.second == :Any
		return "$(a.first)"
	else
		return "$(jvType(a.second)) %$(a.first)"
	end
end

jvType(val::Val{T}) where T = jvType(T)

function jvType(a::Symbol)
	if !isdefined(@__MODULE__, a)
		return string(a)
	elseif typeof(eval(a)) <: UserStruct
		return string(a)
	else
		return jvType(eval(a))
	end
end

jvType(::typeof(*)) = "*"
jvType(::typeof(+)) = "+"
jvType(::typeof(/)) = "/"
jvType(::typeof(-)) = "-"


# TODO nested operations with operator precedence
# For now add brackets manually
function jvOperation(op, x, y)
	if typeof(x) <: Number && typeof(y) <: Number
		return "$(jvType(x)) $op $(jvType(y))"
	else
		return "$x $op $y"
	end
end

jvType(s::String) = s

function jvType(expr::Union{Expr, Type{Expr}})
	if @capture(expr, a_ = b_)
		return "$(jvType(a)) = $(jvType(b))"
	elseif expr.head == :call
		@capture(expr, f_(x_)) && return "$(jvType(eval(f)))($x)"
		@capture(expr, f_(x_, y_)) && f in (:*, :-, :+, :/) && return jvOperation(f, x, y)
		# @capture(expr, f_(x_, y_)) && !(f in (:*, :-, :+, :/)) && return "$(eval(f))($(x), $(y))"
		@capture(expr, f_(x__)) && begin
			xargs = join(jvType.(x), ", ")
			return "$(jvType(eval(f)))($(xargs))"
		end
	elseif @capture(expr,@ptr(ex_))
		return "&$(jvType(ex))"
	elseif @capture(expr, a_::b_)
		return "$(jvType(eval(b))) %$a"
	elseif @capture(expr, a_::b_ = c_)
		return "$a:$(jvType(eval(b))) = $c"
	elseif @capture(expr, a_.b_)
		return "$a.$b"
	elseif @capture(expr, ref_[b_])
		return "$ref[$b]"
	else
		@error "Could not capture $expr !!!"
	end
end
