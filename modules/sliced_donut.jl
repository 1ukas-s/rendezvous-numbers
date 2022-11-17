module_name = "sliced_donut.jl -- by Lukas Stuelke."
using Distributed
d = 0.0
plotter_xlims = (-0.6, 0.6)
plotter_ylims = (-0.1, 0.6)

try
    global d
    d = parse(Float64, replace(replace(split(ARGS[end])[1],"["=>""),"]"=>""))
    println("Inner semicircle diameter: ", d)
catch
    println("\nPlease make the last argument to the command line a 1-value matrix with the diameter ∈[0.0, 1.0] of your inner semicircle, for example: julia ./solver.jl 10 ./modules/sliced_donut.jl \'[0.5]\'")
    exit()
end
if d > 1.0 || d < 0.0
    println("\nPlease make the last argument to the command line a 1-value matrix with the diameter ∈[0.0, 1.0] of your inner semicircle, for example: julia ./solver.jl 10 ./modules/sliced_donut.jl \'[0.5]\'")
    exit()
end
if Distributed.nworkers() > 1
    for i = 2:nworkers()+1
        global d
        remotecall_fetch(()->d, i)
    end
end

Distributed.@everywhere begin
    global p, phi, A, B, d
    p = (1.0+d)*pi/2.0+1.0-d
    phi = pi*(1.0/d+1.0)+2*(1.0/d-1.0)
    A = (1.0-d)/2.0
    B = d*pi/2.0
    function find_diameter() # Defined to be 1 by our parameterization.
        return 1.0
    end

    function param(x) # Parameterizes the unit interval into 2 concentric semicircles of diameter 1 and d[0.0, 1.0].
        global p, phi, A, B, d
        if x <= 0.0 || x >= 1.0
            x = x%1.0
        end
        if x < A/p
            return (p*x-0.5, 0.0)
        elseif x < (A+B)/p
            return ((-d/2.0)*cos(phi*(x-A/p)), (d/2.0)*sin(phi*(x-A/p)))
        elseif x < (2.0*A+B)/p
            return (p*x-A-B+d/2.0, 0.0)
        else
            return (cos(2*(p*x-2*A-B))/2, sin(2*(p*x-2*A-B))/2)
        end
        return (0.0, 0.0)
    end

    function dist(x) # Finds the euclidean distance of two points on the unit interval after paramaterization above.
		p1 = param(x[1])
		p2 = param(x[2])
		return sqrt((p1[1]-p2[1])^2+(p1[2]-p2[2])^2)
	end
end
