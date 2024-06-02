export Scalar, JVScalarType

const JVScalarType = Union{Float32, UInt32, Int32, Bool}

struct Scalar
	element::JVScalarType
end

Base.convert(::Type{JVScalarType}, a::Int64) = JVScalarType(Int32(a))
Base.convert(::Type{JVScalarType}, a::UInt64) = JVScalarType(UInt32(a))
Base.convert(::Type{JVScalarType}, a::Float64) = JVScalarType(Float32(a))

Base.eltype(s::Scalar) = typeof(s.element)
