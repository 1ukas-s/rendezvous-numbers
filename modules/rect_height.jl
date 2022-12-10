module_name = "rect_height.jl -- by Lukas Stuelke."
using Distributed
height = 1.0
plotter_xlims = (-0.1, 1.1)
plotter_ylims = (-0.1, 1.1)

try
    global height
    height = parse(Float64, replace(replace(split(ARGS[end])[1],"["=>""),"]"=>""))
    println("Rectangle with height = $height.")
catch
    println("\nPlease make the last argument to the command line a 1-value matrix with a height ∈[0.0, 1.0], for example julia ./solver.jl 8 \'[0.5]\'")
    exit()
end
if height > 1.0 || height < 0.0
    println("\nPlease make the last argument to the command line a 1-value matrix with a height ∈[0.0, pi/4], for example julia ./solver.jl 8 \'[0.5]\'")
    exit()
end
if Distributed.nworkers() > 1
    for i = 2:nworkers()+1
        global height
        remotecall_fetch(()->height, i)
    end
end
Distributed.@everywhere begin
	global height
	function find_diameter() # Diameter is given by the pythagorean theorem
		return sqrt(1+height^2)
	end

	function param(a)
		global height
		if a <= 0.0 || a >= 1.0
			a = a%1.0
		end
		p = 2+2*height
		a = a*p
		if a <= 1
			toReturn = (a, 0)
		elseif a <= 1 + height
			toReturn = (1, a - 1)
		elseif a <= 2 + height
			toReturn = (2 + height - a, height)
		else
			toReturn = (0, p - a)
		end
		return toReturn
	end

	function dist(x) # Finds the euclidean distance of two points on the unit interval after paramaterization above.
		p1 = param(x[1])
		p2 = param(x[2])
		return sqrt((p1[1]-p2[1])^2+(p1[2]-p2[2])^2)
	end
end
