function kernelFunc(funcExpr)
	if 	@capture(funcExpr, function fname_(fargs__) where Targs__ fbody__ end)
		kernelfunc = quote
			function $fname(args::Tuple{Array}, workgroupSizes, workgroupCount)
				$preparePipeline($(funcExpr), args...)
				$compute($(funcExpr), args...; workgroupSizes=workgroupSizes, workgroupCount=workgroupCount)
				return nothing
			end
		end |> unblock
		return esc(quote $kernelfunc end)
	else
		error("Couldnt capture function")
	end
end

function getFunctionBlock(func, args)
	fString = CodeTracking.definition(String, which(func, args))
	return Meta.parse(fString |> first)
end

function JVCall(kernelObj::JVKernelObject, args...)
	kernelObj.kernelFunc(args...)
end

macro JVkernel(launch, wgSize, wgCount, ex)
	code = quote end
	@gensym f_var kernel_f kernel_args kernel_tt kernel
	if @capture(ex, fname_(fargs__))
		(vars, var_exprs) = assign_args!(code, fargs)
		push!(code.args, quote
				$kernel_args = ($(var_exprs...),)
				$kernel_tt = Tuple{map(Core.Typeof, $kernel_args)...}
				kernel = function JVKernel(args...)
					$preparePipeline($fname, args...; workgroupSizes=$wgSize, workgroupCount=$wgCount)
					$compute($fname, args...; workgroupSizes=$wgSize, workgroupCount=$wgCount)
				end
				if $launch == true
					JVCall(JVKernelObject(kernel), $(kernel_args)...)
				else
					JVKernelObject(kernel)
				end
			end
		)
	end
	esc(code)
end
