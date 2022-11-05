println("ellipse.jl -- by Lukas Stuelke.")
using Distributed
height = -1.0

while isa(height, Float64) == false || height < 0.0 || height > 1.0
    global height
    print("Input the height of the ellipse (Float∈[0.0, 1.0]): ")
    height = parse(Float64, readline(stdin))
end
if Distributed.nworkers() > 1
    for i = 2:nworkers()+1
        global height
        remotecall_fetch(()->height, i)
    end
end

Distributed.@everywhere begin
    function param(x) # Parameterizes the unit interval into a regular polygon.
        global height
        n = height
        return (cos(2*pi*x), height*sin(2*pi*x))
    end

    function dist(x) # Finds the euclidean distance of two points on the unit interval after paramaterization above.
        return sqrt((param(x[1])[1]-param(x[2])[1])^2+(param(x[1])[2]-param(x[2])[2])^2)
    end
end
