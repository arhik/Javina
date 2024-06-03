module Javina

using CodeTracking
using Infiltrator
using StaticArrays

include("ast/scalar.jl")
include("ast/abstracts.jl")
include("ast/macros.jl")
include("ast/variable.jl")
include("ast/scope.jl")
include("ast/assignment.jl")
include("ast/atomics.jl")
include("ast/rangeBlock.jl")
include("ast/conditionBlock.jl")
include("ast/returnBlock.jl")
include("ast/builtin.jl")
include("ast/expr.jl")
include("ast/funcBlock.jl")
include("ast/computeBlock.jl")
include("ast/moduleBlock.jl")
include("ast/exportExpr.jl")
include("ast/infer.jl")
include("ast/resolve.jl")
include("ast/transpile.jl")
include("ast/tree.jl")
include("ast/compile.jl")

# IRGEN
const Vec2{T} = SVector{2, T}
const Vec3{T} = SVector{3, T}
const Vec4{T} = SVector{4, T}
const Mat2{T} = SMatrix{2, 2, T, 4}
const Mat3{T} = SMatrix{3, 3, T, 9}
const Mat4{T} = SMatrix{4, 4, T, 16}
const Vec{N, T} = SVector{N, T}

include("irgen/variableDecl.jl")
include("irgen/struct.jl")
include("irgen/emit.jl")
include("irgen/jvtypes.jl")

export @JVatomic

end # module Javina
