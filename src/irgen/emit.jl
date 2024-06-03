function emitUserField(expr)
	if typeof(expr) == Expr
		if @capture(expr, Array{T_})
			if typeof(T) == Symbol
				return Array{nameof(eval(T))}
			end
		elseif @capture(expr, Array{T_, N_})
			# TODO same as above
			return Array{nameof(eval(T)), eval(N)}
		else
			return jvType(expr)
		end
	end
end

macro user(expr)
	return evalUserField(expr)
end

# TODO this function takes block of fields too
# Another function that makes a sequence of field
# statements is needed.
function evalStructField(fieldDict, field)
	if @capture(field, if cond_ ifblock__ end)
		if eval(cond) == true
			for iffield in ifblock
				evalStructField(fieldDict, iffield)
			end
		end
	elseif @capture(field, if cond_ ifblock__ else elseBlock__ end)
		if eval(cond) == true
			for iffield in ifblock
				evalStructField(fieldDict, iffield)
			end
		else
			for elsefield in elseBlock
				evalStructField(fieldDict, elsefield)
			end
		end
	elseif @capture(field, name_::dtype_)
		return push!(fieldDict, name=>eval(dtype))
	elseif @capture(field, @builtin btype_ name_::dtype_)
		return push!(fieldDict, name=>eval(:(@builtin $btype $dtype)))
	elseif @capture(field, @location btype_ name_::dtype_)
		return push!(fieldDict, name=>eval(:(@location $btype $dtype)))
	elseif @capture(field, quote stmnts__ end)
		for stmnt in stmnts
			evalStructField(fieldDict, stmnt)
		end
	else
		@error "Unknown struct field! $field"
	end
end

function jvStruct(expr)
	expr = MacroTools.striplines(expr)
	expr = MacroTools.flatten(expr)
	@capture(expr, struct T_ fields__ end) || error("verify struct format of $T with fields $fields")
	fieldDict = OrderedDict{Symbol, DataType}()
	for field in fields
		evalfield = evalStructField(fieldDict, field)
	end
	makePaddedStruct(T, fieldDict)
end

# TODO rename simple asssignment and bring back original assignment if needed
function jvAssignment(expr)
	io = IOBuffer()
	if @capture(expr, a_ = b_)
	   @infiltrate
		write(io, "%$(jvType(a)) =w $(jvType(b));\n") # TODO
		seek(io, 0)
		stmnt = read(io, String)
		close(io)
	elseif @capture(expr, a_ += b_) || error("Expecting simple assignment a = b")
		write(io, "$(jvType(a)) += $(jvType(b));\n")
		seek(io, 0)
		stmnt = read(io, String)
		close(io)
	elseif @capture(expr, a_ -= b_) || error("Expecting simple assignment a = b")
		write(io, "$(jvType(a)) -= $(jvType(b));\n")
		seek(io, 0)
		stmnt = read(io, String)
		close(io)
	elseif @capture(expr, a_ *= b_) || error("Expecting simple assignment a = b")
		write(io, "$(jvType(a)) *= $(jvType(b));\n")
		seek(io, 0)
		stmnt = read(io, String)
		close(io)
	elseif @capture(expr, a_ /= b_) || error("Expecting simple assignment a = b")
		write(io, "$(jvType(a)) /= $(jvType(b));\n")
		seek(io, 0)
		stmnt = read(io, String)
		close(io)
	end
	return stmnt
end

# function jvDecisionBlock(io, stmnts; indent=true, indentLevel=0)
# 	for stmnt in stmnts
# 		if indent==true
# 			indentLevel += 1
# 			write(io, " "^(4*indentLevel))
# 		end
# 		jvFunctionStatement(io, stmnt)
# 	end
# end

function jvFunctionStatement(io, stmnt; indent=true, indentLevel=0)
	if indent==true
		write(io, " "^(4*indentLevel))
	end
	if @capture(stmnt, @var t__)
		write(io, jvVariable(stmnt))
	elseif @capture(stmnt, a_ = b_)
		write(io, jvAssignment(stmnt))
	elseif @capture(stmnt, a_ += b_)
		write(io, jvAssignment(stmnt))
	elseif @capture(stmnt, a_ -= b_)
		write(io, jvAssignment(stmnt))
	elseif @capture(stmnt, a_ *= b_)
		write(io, jvAssignment(stmnt))
	elseif @capture(stmnt, a_ /= b_)
		write(io, jvAssignment(stmnt))
	elseif @capture(stmnt, @let t_ | @let t__)
		stmnt.args[1] = Symbol("@letvar") # replace let with letvar
		write(io, jvLet(stmnt))
	elseif @capture(stmnt, return t_)
		write(io, "return %$(jvType(t));\n")
	elseif @capture(stmnt, if cond_ ifblock__ end)
		if cond == true
			jvFunctionStatements(io, ifblock;indent=true, indentLevel=indentLevel)
		end
		# TODO this is incomplete
	elseif @capture(stmnt, f_(a__))
	   write(io, " "^(4*(indentLevel-1))*"$stmnt\n")
	elseif @capture(stmnt, @forloop forLoop_)
		@capture(forLoop, for idx_::idxType_ in range_ block__ end)
		@capture(range, start_:step_:stop_)
		#idxInit = @var Base.eval(:($idx::UInt32 = Meta.parse(jvType(UInt32(r.start - 1)))))
		idxExpr = :($idx::$idxType)
		write(io, "for(var $(jvType(idxExpr)) = $(start); $idx < $(stop); $(idx)++) { \n")
		jvFunctionStatements(io, block; indent=false, indentLevel=indentLevel)
		write(io, " "^(4*indentLevel)*"}\n")
	elseif @capture(stmnt, @escif if cond_ blocks__ end)
		write(io, " "^(4*(indentLevel-1))*"if $cond {\n")
		jvFunctionStatements(io, blocks; indent=false, indentLevel=indentLevel)
		write(io, " "^(4*(indentLevel))*"}\n")
	elseif @capture(stmnt, if cond_ ifBlock__ else elseBlock__ end)
		if eval(cond) == true
			jvFunctionStatements(io, ifBlock; indent=true, indentLevel=indentLevel)
		else
			jvFunctionStatements(io, elseBlock; indent=true, indentLevel=indentLevel)
		end
	elseif @capture(stmnt, @esc st_ )
		if st == :discard
			write(io, "discard;\n")
		else
			@error "This esc statement is not covered yet !!!"
		end
	else
		@error "Failed to capture statment : $stmnt !!"
	end
end

function jvFunctionStatements(io, stmnts; indent=true, indentLevel=0)
	for stmnt in stmnts
		if indent==true
			write(io, " "^(4*indentLevel))
		end
		@infiltrate
		jvFunctionStatement(io, stmnt; indent=true, indentLevel=indentLevel+1)
	end
end

function jvFunctionBody(fnbody, io, endstring)
	if @capture(fnbody[1], fnname_(fnargs__)::fnout_)
		if !(fnname in jvfunctions)
			quote
				function $fnname() end
				jvType(::typeof(eval($fnname))) = string($fnname)
			end |> eval
		end
		write(io, "function \$$fnname(")
		len = length(fnargs)
		endstring = len > 0 ? "}\n" : ""
		for (idx, arg) in enumerate(fnargs)
			if @capture(arg, aarg_::aatype_)
				intype = jvType(eval(aatype))
				write(io, "$(intype) %$aarg"*(len==idx ? "" : ", "))
			elseif @capture(arg, @builtin e_ id_::typ_)
				intype = jvType(eval(typ))
				write(io, "@builtin($e) $id:$(intype)")
			elseif @capture(arg, @location e_ id_::typ_)
				intype = jvType(eval(typ))
				write(io, "@location($e) $id:$(intype)")
			end
			write(io, idx == length(fnargs) ? "" : ", ")
			# TODO what is this check ... not clear
			@capture(fnargs, aarg_) || error("Expecting type for function argument in jv!")
		end
		outtype = jvType(eval(fnout))
		write(io, ") -> $outtype { \n")
		@capture(fnbody[2], stmnts__) || error("Expecting quote statements")
		jvFunctionStatements(io, stmnts)
	elseif @capture(fnbody[1], fnname_(fnargs__))
		write(io, "function \$$fnname(")
		len = length(fnargs)
		endstring = len > 0 ? "}\n" : ""
		for (idx, arg) in enumerate(fnargs)
			@capture(arg, aarg_::aatype_)
		    intype = jvType(eval(aatype))
			write(io, "$(intype) %$aarg"*(len==idx ? "" : ", "))
			#write(io, idx == length(fnargs) ? "" : ", ")
			# TODO what is this check ... not clear
			@capture(fnargs, aarg_) || error("Expecting type for function argument in jv!")
		end
		write(io, ") { \n")
		write(io, "@start\n")
		@capture(fnbody[2], stmnts__) || error("Expecting quote statements")
		jvFunctionStatements(io, stmnts)
	end
	write(io, endstring)
end


function jvFunction(expr)
	io = IOBuffer()
	endstring = ""
	@capture(expr, function fnbody__ end) || error("Expecting regular function!")
	jvFunctionBody(fnbody, io, endstring)
	seek(io, 0)
	code = read(io, String)
	close(io)
	return code
end

function jvVariable(expr)
	io = IOBuffer()
	write(io, jvType(eval(expr)))
	seek(io, 0)
	code = read(io, String)
	close(io)
	return code
end

# TODO for now both jvVariable and jvLet are same
function jvLet(expr)
	io = IOBuffer()
	@capture(expr, @letvar rest_)
	@infiltrate
	write(io, "$(jvAssignment(rest))")
	seek(io, 0)
	code = read(io, String)
	close(io)
	return code
end


function jvConstVariable(block)
	@capture(block, @const constExpr_)
	return "const $(jvType(constExpr));\n"
end


# IOContext TODO
function jvCode(expr)
	io = IOBuffer()
	expr = MacroTools.striplines(expr)
	expr = MacroTools.flatten(expr)
	@capture(expr, blocks__) || error("Current expression is not a quote or block")
	for block in blocks
		if @capture(block, struct T_ fields__ end)
			write(io, jvStruct(block))
		elseif @capture(block, a_ = b_)
			write(io, jvAssignment(block))
		elseif @capture(block, @var t__)
			write(io, jvVariable(block))
		elseif @capture(block, @const ct__)
			write(io, jvConstVariable(block))
		elseif @capture(block, function a__ end)
			write(io, jvFunction(block))
			write(io, "\n")
		elseif @capture(block, if cond_ ifblock_ end)
			if eval(cond) == true
				write(io, jvCode(ifblock))
				write(io, "\n")
			end
		elseif @capture(block, if cond_ ifBlock_ else elseBlock_ end)
			if eval(cond) == true
				write(io, jvCode(ifBlock))
				write(io, "\n")
			else
				write(io, jvCode(elseBlock))
				write(io, "\n")
			end
		end
	end
	seek(io, 0)
	code = read(io, String)
	close(io)
	return code
end
