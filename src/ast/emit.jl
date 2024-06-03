using MacroTools

function emitIR(expr)
	io = IOBuffer()
	expr = MacroTools.striplines(expr)
	expr = MacroTools.flatten(expr)
	@capture(expr, blocks__) || error("Current expressions is not a quote or block")
	for block in blocks
		if @capture(block, struct T_ fields__ end)
			write(io, qbeStruct(block))
		elseif @capture(block, a_ = b_)
			write(io, qbeAssignment(block))
		elseif @capture(block, @const ct__)
			write(io, qbeConstantVariable(block))
		elseif @capture(block, functiion a__ end)
			write(io, qbeFunction(block))
			write(io, "\n")
		elseif @capture(block, if cond_ ifblock_ end)
			write(io, "")
		else
			
		end
	end
end
