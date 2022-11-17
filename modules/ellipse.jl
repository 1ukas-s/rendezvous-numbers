module_name = "ellipse.jl -- by Lukas Stuelke."
using Distributed
height = 1.0
secline_ang1 = 0.0
secline_ang2 = 0.0
plotter_xlims = (-0.6, 0.6)
plotter_ylims = (-0.6, 0.6)

try
    global height
    height = parse(Float64, replace(replace(split(ARGS[end], ",")[1],"["=>""),"]"=>""))
    println("Ellipse vertical diameter: $(height)")
catch
    global height
    println("\nPlease make the last argument to the command line a 1-value matrix with the height ratio ∈[0.0, 1.0] of your ellipse, for example julia ./solver.jl 8 \'[0.5]\'")
    height = 1.0
end
try
    global secline_ang1
    secline_ang1 = parse(Float64, replace(replace(split(ARGS[end], ",")[2],"["=>""),"]"=>""))
    println("The secant slicing line segment has an endpoint at ($(cos(secline_ang1)), $(sin(secline_ang1))) given by angle $(secline_ang1).")
catch
    global secline_ang1
    println("\nPlease make the last argument to the command line a 3-value matrix with the height ratio ∈[0.0, 1.0] of your ellipse and two points on the ellipse which make a secant line ∈[0.0, $(2*pi)] for example julia ./solver.jl 8 \'[0.5]\'")
    secline_ang1 = 0.0
end
try
    global secline_ang2
    secline_ang2 = parse(Float64, replace(replace(split(ARGS[end], ",")[3],"["=>""),"]"=>""))
    println("The secant slicing line segment has an endpoint at ($(cos(secline_ang1)), $(sin(secline_ang1))) given by angle $(secline_ang1).")
catch
    global secline_ang2
    println("\nPlease make the last argument to the command line a 3-value matrix with the height ratio ∈[0.0, 1.0] of your ellipse and two points on the ellipse which make a secant line ∈[0.0, $(2*pi)] for example julia ./solver.jl 8 \'[0.5,3.14,1.57]\'")
    secline_ang2 = 0.0
end
if height > 1.0 || height < 0.0 || secline_ang1 > 2.0*pi || secline_ang1 < 0.0 || secline_ang2 > 2.0*pi || secline_ang2 < 0.0
    println("\nPlease make the last argument to the command line a 3-value matrix with the height ratio ∈[0.0, 1.0] of your ellipse and two points on the ellipse which make a secant line ∈[0.0, $(2*pi)] for example julia ./solver.jl 8 \'[0.5,3.14,1.57]\'")
    exit()
end
a1 = min(secline_ang1, secline_ang2)/(2*pi)
a2 = max(secline_ang1, secline_ang2)/(2*pi)
if Distributed.nworkers() > 1
    for i = 2:nworkers()+1
        global height, a1, a2
        remotecall_fetch(()->height, i)
        remotecall_fetch(()->a1, i)
        remotecall_fetch(()->a2, i)
    end
end

Distributed.@everywhere begin
    function find_diameter() # Defined to be 1 by our parameterization.
        return 1.0
    end
    if a1 == a2
        function param(x) # Parameterizes the unit interval into a regular polygon.
            global height
            return (cos(2*pi*x)/2.0, height*sin(2*pi*x)/2.0)
        end
    else
        global height, a1, a2, csa, sna, coffx, termx, coffy, termy
        csa = cos(2*pi*a1)/2
        sna = height*sin(2*pi*a1)/2
        coffx = (cos(2*pi*a2)-cos(2*pi*a1))/(2*(a2-a1))
        termx = csa-(cos(2*pi*a2)-cos(2*pi*a1))/(2*(a2-a1))*a1
        coffy = height*(sin(2*pi*a2)-sin(2*pi*a1))/(2*(a2-a1))
        termy = sna-height*(sin(2*pi*a2)-sin(2*pi*a1))/(2*(a2-a1))*a1
        function param(x)
            x = x%1
            global height, a1, a2, csa, sna, coffx, termx, coffy, termy
            if x <= a1 || x >= a2
                return (cos(2*pi*x)/2, height*sin(2*pi*x)/2)
            else
                return (coffx*x+termx, coffy*x+termy)
            end
        end
    end


    function dist(x) # Finds the euclidean distance of two points on the unit interval after paramaterization above.
		p1 = param(x[1])
		p2 = param(x[2])
		return sqrt((p1[1]-p2[1])^2+(p1[2]-p2[2])^2)
	end
end
