module_name = "ngon_height.jl -- by Lukas Stuelke."
using Distributed
num_sides = 0
height = 1.0


try
    global num_sides, height
    num_sides = parse(Int, replace(replace(split(ARGS[end])[1],"["=>""),"]"=>""))
    height = parse(Float64, replace(replace(split(ARGS[end])[2],"["=>""),"]"=>""))
catch
    println("\nPlease make the last argument to the command line a 2-value matrix with the number of sides an Integer > 2, and the height ∈[0.0, 1.0] of your circumelliptical arc, separated without a space. For example, julia ./solver.jl 2 6 \'[12 0.75]\'")
    exit()
end
if height > 1.0 || height < 0.0 || num_sides < 2
    println("\nPlease make the last argument to the command line a 2-value matrix with the number of sides an Integer > 2, and the height ∈[0.0, 1.0] of your circumelliptical arc, separated without a space. For example, julia ./solver.jl 2 6 \'[12 0.75]\'")
    exit()
end
println("Stretch value for vertical axis: ", height)
println("Number of sides: ", num_sides)
if Distributed.nworkers() > 1
    for i = 2:nworkers()+1
        global num_sides, height
        remotecall_fetch(()->num_sides, i)
        remotecall_fetch(()->height, i)
    end
end

plotter_xlims = (-0.1, 1.1)
plotter_ylims = (-0.6, 0.6)

Distributed.@everywhere begin
    function find_diameter() # Finds the diameter of a regular polygon using symmetries.
        global num_sides, height
        n = num_sides
        if n%2 == 0
            return 1.0
        end
        x = (n+n%2)/(2*n)
        x_b = ceil(x*n) # x between: x is this and the next vertex
        x_a = (x*n)%1 # x along: how far is x between them (%)
        return sqrt(((1-cos((2*π*x_b-2*π)/n)*(1-x_a)-cos((2*π*x_b)/n)*x_a)/2.0)^2 + ((sin((2*π*x_b-2*π)/n)*(1-x_a)+sin((2*π*x_b)/n)*x_a)/2.0)^2)/2.0
    end

    function param(x) # Parameterizes the unit interval into a regular polygon.
        global num_sides, height
        n = num_sides
        pin = π/n
        x_f = 2*floor(x*n)+1
        return ((1-cos(pin)*cos(pin*x_f)+(2*x*n-x_f)*sin(pin)*sin(pin*x_f))/2.0, height*(cos(pin)*sin(pin*x_f)+(2*x*n-x_f)*sin(pin)*cos(pin*x_f))/2.0)
    end

    function dist(x) # Finds the euclidean distance of two points on the unit interval after paramaterization above.
        return sqrt((param(x[1])[1]-param(x[2])[1])^2+(param(x[1])[2]-param(x[2])[2])^2)
    end
end
