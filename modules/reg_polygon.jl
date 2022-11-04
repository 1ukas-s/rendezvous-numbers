println("reg_polygon.jl -- by Lukas Stuelke.")
using Distributed
num_sides = 0

while isa(num_sides, Signed) == false || num_sides < 2
    global num_sides
    print("Input the number of sides for your regular polygon (Int > 2): ")
    num_sides = parse(Int, readline(stdin))
end

for i = 2:nworkers()+1
    global num_sides
    remotecall_fetch(()->num_sides, i)
end

Distributed.@everywhere begin
    function magic_number() # Calculates the magic number of a regular polygon for comparison to optimizer's results.
        global num_sides
        x = num_sides
        toReturn = 0.0
        if x%2 == 0
            for k = 0:x-1
                toReturn += sqrt(1.5+0.5*cos(2*π/x)-cos(2*k*π/x)-cos(2*(k-1)*π/x))/(2*x)
            end
        elseif x%2 == 1
            for k = 0:x-1
                toReturn += sqrt((1.5+0.5*cos(2*π/x)-cos(2*k*π/x)-cos(2*(k-1)*π/x))/(2-2*cos((x-1)*π/x)))/x
            end
        else
            return 0.0
        end
        return toReturn
    end

    function find_diameter() # Finds the diameter of a regular polygon using symmetries.
        global num_sides
        n = num_sides
        if n%2 == 0
            return 2.0
        end
        x = (n+n%2)/(2*n)
        x_b = ceil(x*n) # x between: x is this and the next vertex
        x_a = (x*n)%1 # x along: how far is x between them (%)
        return sqrt((1-cos((2*π*x_b-2*π)/n)*(1-x_a)-cos((2*π*x_b)/n)*x_a)^2 + (sin((2*π*x_b-2*π)/n)*(1-x_a)+sin((2*π*x_b)/n)*x_a)^2)
    end

    function param(x) # Parameterizes the unit interval into a regular polygon.
        global num_sides
        n = num_sides
        pin = π/n
        x_f = 2*floor(x*n)+1
        return (1-cos(pin)*cos(pin*x_f)+(2*x*n-x_f)*sin(pin)*sin(pin*x_f), cos(pin)*sin(pin*x_f)+(2*x*n-x_f)*sin(pin)*cos(pin*x_f))
    end

    function dist(x) # Finds the euclidean distance of two points on the unit interval after paramaterization above.
        return sqrt((param(x[1])[1]-param(x[2])[1])^2+(param(x[1])[2]-param(x[2])[2])^2)
    end
end
