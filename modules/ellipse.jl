module_name = "ellipse.jl -- by Lukas Stuelke."
using Distributed
height = 1.0
plotter_xlims = (-0.6, 0.6)
plotter_ylims = (-0.6, 0.6)

try
    global height
    height = parse(Float64, replace(replace(split(ARGS[end])[1],"["=>""),"]"=>""))
    println("Ellipse vertical diameter: ", height)
catch
    println("\nPlease make the last argument to the command line a 1-value matrix with the height ∈[0.0, 1.0] of your ellipse, for example julia ./solver.jl 2 6 \'[0.5]\'")
    exit()
end
if height > 1.0 || height < 0.0
    println("\nPlease make the last argument to the command line a 1-value matrix with the height ∈[0.0, 1.0] of your ellipse, for example julia ./solver.jl 2 6 \'[0.5]\'")
    exit()
end
if Distributed.nworkers() > 1
    for i = 2:nworkers()+1
        global height
        remotecall_fetch(()->height, i)
    end
end

Distributed.@everywhere begin
    function find_diameter() # Defined to be 1 by our parameterization.
        return 1.0
    end

    function param(x) # Parameterizes the unit interval into a regular polygon.
        global height
        return (cos(2*pi*x)/2.0, height*sin(2*pi*x)/2.0)
    end

    function dist(x) # Finds the euclidean distance of two points on the unit interval after paramaterization above.
		p1 = param(x[1])
		p2 = param(x[2])
		return sqrt((p1[1]-p2[1])^2+(p1[2]-p2[2])^2)
	end
end
