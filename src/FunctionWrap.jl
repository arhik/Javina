using Infiltrator

baremodule Add2Ints

using Base

struct H
	a::Int64
	b::Int64
end

function addInts(a::Int64, b::Int64)
	c = a + b
	return c
end

function workit(a::Int64, b::Int64, c::Int64)
	d = addInts(b, c)
	e = a + d
	return e
end

end

atypes = Tuple{Int, Int, Int} # argument types
mths = methods(Add2Ints.workit, atypes) # worth checking that there is only one
m = first(mths)
# Create variables needed to call `typeinf_code`
interp = Core.Compiler.NativeInterpreter()
sparams = Core.svec() # this particular method doesnot have type-parameters
run_optimizer = false # run all inference optimizations
#types = Tuple{typeof(convert), atypes.parameters...} # Tuple{typeof(convert), Type{Int}, UInt}
aa = Core.Compiler.typeinf_code(interp, m, atypes, sparams, run_optimizer)[1]

using MacroTools

transpile(io, ::Type{Int64}) = write(io, "w")
transpile(io, ::Type{Float64}) = write(io, "d")
transpile(io, ::Type{Float32}) = write(io, "s")
transpile(io, ::Type{Int32}) = write(io, "s")

transpile(::Type{Int64}) = "w"
transpile(::Type{Float64}) = "d"
transpile(::Type{Float32}) = "s"
transpile(::Type{Int32}) = "s"
transpile(::Type{T}) where T = string(T)

function transpile(io, ir, f::GlobalRef, a, b)
	write(io, "$ssaidx =w add %$(ir.ssa) %b")
end

function transpile(io, ci, f, c::Core.SlotNumber, a::Core.SlotNumber, b::Core.SlotNumber)
	write(io, "\t%$(ci.slotnames[c.id]) =w add %$(ci.slotnames[a.id]), %$(ci.slotnames[b.id])\n")
end

function transpile(io, ci, a::Core.SlotNumber)
	write(io, "\tret %$(ci.slotnames[a.id])\n")
end

function transpile(io, ssaidx, code, ir)
	if @capture(ir, f_(a_, b_))
		transpile(io, code, f, a, b)
	elseif @capture(ir, c_ = f_(a_, b_))
		transpile(io, code, f, c, a, b)
	elseif isa(ir, Core.ReturnNode)
		transpile(io, code, ir.val)
	else
		@error "Failed to capture $ir"
	end
end

function qbeIR(io, code)
	for (ssaidx, ir) in enumerate(code.code)
		transpile(io, ssaidx, code, ir)
	end
end

function compileFunction(io, msym::Function)
	ms = msym |> methods
	@assert length(ms) == 1 "ERROR: Method Ambiguity. $mod:$sym is ambiguous."
	mthd = first(ms)
	(code, ret) = Core.Compiler.typeinf_code(interp, mthd, mthd.sig, sparams, run_optimizer)
	@assert ret != Any "ERROR: Type inference failed to infer Return type!!!"
	write(io, "function $(transpile(ret)) \$$(mthd.name)(")
	argTypes = mthd.sig.parameters[2:mthd.nargs]
	args = Symbol.(split(mthd.slot_syms, "\0")[2:mthd.nargs])
	let i = 0; 
		for (arg, argType) in  zip(args, argTypes)
			arg_qbeType = transpile(argType)
			write(io, i < mthd.nargs - 2 ? "$arg_qbeType %$(arg), " : "$arg_qbeType %$(arg)")
			i += 1
		end
	end
	write(io, ") {\n")
	write(io, "@start\n")
	qbeIR(io, code)
	write(io, "}\n\n")
end

function compileAggregate(io, h::DataType)
	write(io, "type :$(nameof(h)) = { ")
	let fc = 1;
		for (field, ftype) in zip(fieldnames(h), fieldtypes(h))
			write(io, fieldcount(h) > fc ? "$(transpile(ftype)), " : "$(transpile(ftype)) ")
			fc += 1
		end
	end
	write(io, "}\n\n")
end

function compileModule(mod::Module, static::Bool=true)
	io = IOBuffer()
	write(io, "# [ MODULE $(nameof(mod)) ] \n\n")
	for sym in names(mod, all=true, imported=false)
		if startswith(sym |> string, "#")
			continue
		elseif sym == nameof(mod)
			continue
		else
			msym = getproperty(mod, sym)
			if isa(msym, Function)
				compileFunction(io, msym)
			elseif isstructtype(msym)
				compileAggregate(io, msym)
			end
		end
	end
	write(io, 
		"""
		# [ MAIN ]
		export function w \$main() {				# Main function
		@start
			%r =w call \$workit(w 1000, w 10, w 33)			# Call add(1, 1)
			call \$printf(l \$fmt, ..., w %r)    	# Show the result
			ret 0
		}
		
		data \$fmt = { b "One and one make %d!\\n", b 0 }
		"""
	)
	seek(io, 0)
	qbecode = take!(io)
	qbessa = pointer(qbecode) |> unsafe_string

	@info qbessa
	
	open("$(nameof(mod)).ssa", "w") do f
		write(f, qbessa)
		close(f)
	end
	
	@sync   begin
		cmd1 = Cmd(`qbe -o $(nameof(mod)).s $(nameof(mod)).ssa`)
		cmd2 = Cmd(`cc -o $(nameof(mod)).jn $(nameof(mod)).s`)
		cmd3 = Cmd(`$(nameof(mod)).jn`)
		result = success(
			run(
				pipeline(
					pipeline(cmd1, cmd2, cmd3),
				),
			)
		)	
	end
end

compileModule(Add2Ints)


