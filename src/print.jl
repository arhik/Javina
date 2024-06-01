
abstract type AbstractQBEType end

compile(a::AbstractQBEType) = print(a)

struct DataString <: AbstractQBEType
	s::String
end

struct QBEVar <: AbstractQBEType
	s::Symbol
end

function compile(s::QBEVar)
	
end

function compile(dataString::DataString)
	return """data \$str = { b "$(dataString.s)", b 0 }"""
end

function print(s::String)
	quote
		@data s = { b "$s", b 0 }
		@export function main()
			@start begin
				r = @w call puts(@l str)
			end
		end 
	end
end

"""
# Define the string constant.
data $str = { b "hello world", b 0 }

export function w $main() {
@start
        # Call the puts function with $str as argument.
        %r =w call $puts(l $str)
        ret 0
}
"""
