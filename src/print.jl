struct DataString
	name::Symbol
	str::String
end

a = DataString(:hello, "Hello World!|| How are you ?")
b = DataString(:hello2, "Hello World!|| How arfdse fdsasdfasdfasdfasdfasfdyou ?")
c = DataString(:hello3, "Hello World!|| How arsdfasdfe you ?")
d = DataString(:hello4, "Hello Woasdfasdfrld!|| How are you ?")
e = DataString(:hello5, "Hello Wo are you ?")
s = DataString(:hello5, "Hello Wo are you ?")


function print(s::DataString)
	a = """
		# Define the string constant.
		data \$$(s.name) = { b "$(s.str)", b 0 }
		
		export function w \$main() {
		@start
		        # Call the puts function with \$str as argument.
		        %r =w call \$puts(l \$$(s.name))
		        ret 0
		}
		"""
	open("print.ssa", "w") do f
		write(f, a)
		close(f)
	end
	cmd1 = Cmd(`qbe -o print.s print.ssa`)
	cmd2 = Cmd(`cc -o print print.s`)
	cmd3 = Cmd(`./print`)
	result = success(
		run(
			pipeline(
				pipeline(cmd1, cmd2, cmd3),
			), 
		)
	)
	return nothing
end

print(a)
print(b)
print(c)
print(d)
print(e)


# Lets play with abstract Interpreter now ... 

baremodule Add2Ints

using Base

struct H
	a::Float32
	b::Float64
end

function add2Ints(a::Int64, b::Int64)
	c = a + b
	return c
end

function workit(a::Int64, b::Int64, c::Int64)
	d = add2Ints(b, c)
	e = d + a
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

function transpile(io, ir, f::GlobalRef, a, b)
	write(io, "$ssaidx =w add %$(ir.ssa) %b")
end

function transpile(io, ci, f, c::Core.SlotNumber, a::Core.SlotNumber, b::Core.SlotNumber)
	write(io, "%$(ci.slotnames[c.id]) =w add %$(ci.slotnames[a.id]) %$(ci.slotnames[b.id])\n")
end

function transpile(io, ssaidx, code, ir)
	if @capture(ir, f_(a_, b_))
		transpile(io, code, f, a, b)
	elseif @capture(ir, c_ = f_(a_, b_))
		transpile(io, code, f, c, a, b)
	elseif @capture(ir, return a_)
		#transpile(io, ir)
	end
end

function qbeIR(io, ci)
	(code, ret) = ci
	for (ssaidx, ir) in enumerate(code.code)
		@info (ssaidx, ir)
		transpile(io, ssaidx, code, ir)
	end
end

function compileFunction(io, f::Function)
	write(io, "function ")
	ms = msym |> methods
	@assert length(ms) == 1 "ERROR: Method Ambiguity. $mod:$sym is ambiguous."
	mthd = first(ms)
	ci = Core.Compiler.typeinf_code(interp, mthd, mthd.sig, sparams, run_optimizer)
	@info (ci |> first).rettype
	@assert (ci |> last) != Any "ERROR: Type inference failed to infer Return type!!!"
	qbeIR(io, ci)	
end

function compileAggregate(io, h::DataType)
	write(io, "type :$(nameof(h)) = { ")
	for (idx, (field, ftype)) in enumerate(zip(fieldnames(h), fieldtypes(h)))
		write(io, fieldcount(h) != idx ? "$ftype, " : "$ftype ")
	end
	write(io, "}\n")
end

function compileModule(mod::Module, static::Bool=true)
	io = IOBuffer()
	for sym in names(mod, all=true, imported=false)
		if startswith(sym |> string, "#")
			continue
		elseif sym == nameof(mod)
			continue
		else
			msym = getproperty(mod, sym)
			if isa(msym, Function)
				
			elseif isstructtype(msym)
				compileAggregate(io, msym)
			end
		end
	end
	write(io, """
		export function w \$main() {                # Main function
		@start
			%r =w call \$add2Ints(w 1, w 1)          # Call add(1, 1)
			call \$printf(l \$fmt, ..., w %r)    # Show the result
			ret 0
		}
		data \$fmt = { b "One and one make %d!\\n", b 0 }
	""")
	seek(io, 0)
	qbecode = take!(io)
	qbessa = pointer(qbecode) |> unsafe_string
	println(qbessa)
end

compileModule(Add2Ints)



