struct DataString
	name::Symbol
	str::String
end

a = DataString(:hello, "Hello World!|| How are you ?")
b = DataString(:hello2, "Hello World!|| How arfdse fdsasdfasdfasdfasdfasfdyou ?")
c = DataString(:hello3, "Hello World!|| How arsdfasdfe you ?")
d = DataString(:hello4, "Hello Woasdfasdfrld!|| How are you ?")
e = DataString(:hello5, "Hello Wo are you ?")

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
	f = open("print.ssa", "w")
	write(f, a)
	close(f)
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
	if result
		@info read(stdout)
	else
		@error read(stderr)
	end
	return nothing
end

print(a)
print(b)
print(c)
print(d)
print(e)
