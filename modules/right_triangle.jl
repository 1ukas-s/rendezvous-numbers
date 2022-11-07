module_name = "right_triangle.jl -- by Lukas Stuelke."
using Distributed
ang = pi/4

try
    global ang
    ang = parse(Float64, replace(replace(split(ARGS[end])[1],"["=>""),"]"=>""))
    println("Right triangle with one angle = ", ang, ".")
catch
    println("\nPlease make the last argument to the command line a 1-value matrix with an angle ∈[0.0, pi/4], for example julia ./solver.jl 2 6 \'[0.392]\'")
    exit()
end
if ang > pi/4 || ang < 0.0
    println("\nPlease make the last argument to the command line a 1-value matrix with an angle ∈[0.0, pi/4], for example julia ./solver.jl 2 6 \'[0.392]\'")
    exit()
end
if Distributed.nworkers() > 1
    for i = 2:nworkers()+1
        global ang
        remotecall_fetch(()->ang, i)
    end
end
Distributed.@everywhere begin
	function find_diameter() # Diameter defined to be 1 by our parameterization below
		return 1.0
	end

	function param(a)
		global ang
		csa = cos(ang)
		sna = sin(ang)
		m = csa+sna+1
		if a <= 0 || a >= 1
			toReturn = (0, 0)
		elseif a <= csa/m
			toReturn = (m*a, 0)
		elseif a <= (csa+1)/m
			toReturn = (csa*(1+csa-m*a), sna*(m*a-csa))
		else
			toReturn = (0, m*(1-a))
		end
		return toReturn
	end

	function dist(x) # Finds the euclidean distance of two points on the unit interval after paramaterization above.
		return sqrt((param(x[1])[1]-param(x[2])[1])^2+(param(x[1])[2]-param(x[2])[2])^2)
	end
end
