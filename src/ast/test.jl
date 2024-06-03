using Revise
using CodeTracking
using Chairmarks
using Javina
using Javina: Generic, JVVariable

makeVarPair(p::Pair{Symbol, DataType}) = p.first => JVVariable(
	p.first, p.second, Generic, nothing, false, true
)

# ------

scope = Scope(
	Dict(
		makeVarPair(:b=>Int32),
		makeVarPair(:c=>Int32),
	),
	Dict(),	Dict(), 0, nothing, quote end
)

aExpr = inferExpr(scope, :(a::Int32 = b + c))
#bExpr = inferExpr(scope, :(a::Int32 = b + c))
transpile(scope, aExpr)

# ------
scope = Scope(
	Dict(
		makeVarPair(:b=>Int32),
		makeVarPair(:c=>Int32),
	),
	Dict(),	Dict(), 0, nothing, quote end
)

aExpr = inferExpr(scope, :(a::Int32 = b + c))
bExpr = inferExpr(scope, :(a = b + c))
transpile(scope, aExpr)
transpile(scope, bExpr)

# ------

scope = Scope(
	Dict(
		makeVarPair(:b=>Int32),
		makeVarPair(:c=>Int32),
	),
	Dict(),	Dict(), 0, nothing, quote end
)

aExpr = inferExpr(scope, :(a = b + c))
vExpr = inferExpr(scope, :(a = b + c))

transpile(scope, aExpr)
transpile(scope, vExpr)

# ------

scope = Scope(
	Dict(
		makeVarPair(:b=>Int32),
		makeVarPair(:c=>Int32),
	),
	Dict(),	Dict(), 0, nothing, quote end
)

aExpr = inferExpr(scope, :(a = b + c))
bExpr = inferExpr(scope, :(a = c))
transpile(scope, aExpr)
transpile(scope, bExpr)

# ------

scope = Scope(
	Dict(
		makeVarPair(:b=>Int32),
		makeVarPair(:c=>Int32),
	),
	Dict(),	Dict(), 0, nothing, quote end
)


aExpr = inferExpr(scope, :(a = b + c))
transpile(scope, aExpr)

# -------

# TODO rerunning transpile(scope, aExpr) will have declexpr for a lik a::Int32 which is a bug

# This should fail variable a in rhs is not in scope
scope = Scope(
	Dict(
		makeVarPair(:b=>Int32),
		makeVarPair(:c=>UInt32),
		makeVarPair(:(+)=>Function),
		makeVarPair(:g=>Function)
	),
	Dict(),
	Dict(), 0, nothing, quote end
)
cExpr = inferredExpr = inferExpr(scope, :(a::Int32 = g(a + b + c) + g(2, 3, c)))
transpile(scope, cExpr)

# This should fail too datatypes are different
scope = Scope(
	Dict(
		makeVarPair(:b=>Int32),
		makeVarPair(:c=>UInt32),
		makeVarPair(:(+)=>Function),
		makeVarPair(:g=>Function)
	),
	Dict(),
	Dict(), 0, nothing, quote end
)
cExpr = inferredExpr = inferExpr(scope, :(a::Int32 = g(b + c) + g(2, 3, c)))
transpile(scope, cExpr)

# ------
# This should fail too
scope = Scope(
	Dict(
		makeVarPair(:b=>Int32),
		makeVarPair(:c=>UInt32),
		makeVarPair(:(+)=>Function),
		makeVarPair(:g=>Function)
	),
	Dict(),
	Dict(), 0, nothing, quote end
)

cExpr = inferredExpr = inferExpr(scope, :(a::Int32 = g(b + c) + g(2.0, 3, c)))
transpile(scope, cExpr)

# ------
scope = Scope(
	Dict(
		makeVarPair(:b=>UInt32),
		makeVarPair(:c=>UInt32),
		makeVarPair(:(+)=>Function),
		makeVarPair(:g=>Function)
	),
	Dict(),
	Dict(), 0, nothing, quote end
)
inferredExpr = inferExpr(scope, :(a::UInt32 = ( b + g(b + c))))
transpile(scope, inferredExpr)

# ----
scope = Scope(
	Dict(
		makeVarPair(:a=>Array{UInt32, 16}),
		makeVarPair(:d=>UInt32),
		makeVarPair(:c=>UInt32),
		makeVarPair(:b=>Array{UInt32, 16}),
		makeVarPair(:(+)=>Function),
		makeVarPair(:g=>Function)
	),
	Dict(),
	Dict(), 0, nothing, quote end
)

inferredExpr = inferExpr(scope, :(a[d] = c + b[1])) #TODO 1 is a scalar Int32 will fail
transpile(scope, inferredExpr)

# -----
struct B
	b::Array{Int32, 16}
end

scope = Scope(
	Dict(
		makeVarPair(:a=>Array{Int32, 16}),
		makeVarPair(:c=>UInt32),
		makeVarPair(:g=>B),
		makeVarPair(:(+)=>Function)
	), Dict(), Dict(), 0, nothing, quote end)
inferredExpr = inferExpr(scope, :(a[c] = g.b[1]))
transpile(scope, inferredExpr)

# -----
struct B
	b::Array{Int32, 16}
end

struct C
	c::Array{Int32, 16}
end

scope = Scope(Dict(
	makeVarPair(:a=>C),
	makeVarPair(:g=>B)
	), Dict(), Dict(), 0, nothing, quote end)
inferredExpr = inferExpr(scope, :(a.c[1] = g.b[1])) # scalar indexes will fail
transpile(scope, inferredExpr)
# -----

scope = Scope(
	Dict(
		makeVarPair(:a=>Array{Float32, 16}),
		makeVarPair(:b=>Array{Float32, 16}),
		makeVarPair(:c=>Array{Float32, 16}),
		makeVarPair(:d=>Array{Float32, 16}),
		makeVarPair(:println=>Function),
		makeVarPair(:(+)=>Function)
	), Dict(), Dict(), 0, nothing, quote end
)

inferredExpr = inferExpr(
	scope,
	:(for i in 0:1:12
		println(i)
		a[10 % i] = b[i]
		c[i] = d[i] + c[i] + 1.0
	end)
)

transpile(scope, inferredExpr)

# -----

scope = Scope(
	Dict(
		makeVarPair(:a=>Array{Float32, 16}),
		makeVarPair(:b=>Array{Float32, 16}),
		makeVarPair(:c=>Array{Float32, 16}),
		makeVarPair(:d=>Array{Float32, 16}),
		makeVarPair(:println=>Function),
		makeVarPair(:(+)=>Function)
	), Dict(), Dict(), 0, nothing, quote end
)

inferredExpr = inferExpr(
	scope,
	:(for i in 0:1:12
		for j in 1:2:40
			println(i, j)
			a[j] = b[i]
			c[i] = d[i] + c[i] + 1.0
		end
	end)
)

transpile(scope, inferredExpr)

# -----

scope = Scope(
	Dict(
		#makeVarPair(:x=>Int32),
		makeVarPair(:a=>Array{Float32, 16}),
		makeVarPair(:b=>Array{Float32, 16}),
		makeVarPair(:c=>Array{Float32, 16}),
		makeVarPair(:d=>Array{Float32, 16}),
		makeVarPair(:println=>Function),
		makeVarPair(:(+)=>Function)
	), Dict(), Dict(), 0, nothing, quote end
)

inferredExpr = inferExpr(
	scope,
	:( for i in 1:10
		if x == 0
			println(i)
			a[i] = b[i]
			c[i] = d[i] + c[i] + 1.0
		end
		end
	)
)

transpile(scope, inferredExpr)

# ----

scope = Scope(
	Dict(
		makeVarPair(:println=>Function)
	),
	Dict(),
	Dict(), 0, nothing, quote end
)

inferredExpr = inferExpr(
	scope,
	:(function test(a::Float32, b::Float32)
		for i in 1:10
			println(i)
		end
	end)
)

transpile(scope, inferredExpr)

# ----------

using Javina
using Javina: jvCode

jvCode(transpile(scope, inferredExpr))


# ----------

scope = Scope(
	Dict(
		makeVarPair(:println=>Function)
	),
	Dict(),
	Dict(), 0, nothing, quote end
)

inferredExpr = inferExpr(
	scope,
	:(function add(a::UInt32, b::UInt32)
		c = a + b
		return c
	end)
)

transpile(scope, inferredExpr)

# ----------

using Javina
using Javina: jvCode

jvCode(transpile(scope, inferredExpr)) |> println

# ----------


