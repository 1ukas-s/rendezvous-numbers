# The solver script will print this at the start and end so you know which module was used. If this isn't defined, it'll print the file path.
module_name = "example.jl -- by Lukas Stuelke."

# We call "using Distributed" here so that the following parameters and functions can be defined on all processes.
using Distributed

# Example parameters that the user of solver.jl or plotter.jl will overwrite.
# Just put a number in so that their type is what it should be, since they will be overwritten.

parameter_1 = 1.0 # Float
parameter_2 = 5 # Int

# The following two variables are only for when the parameterization of your plot needs to change the bounds of the plot in plotter.
# For example, the parameterization of a square might be seen in the first quadrant, but the ellipse should just zoom out of the origin.
plotter_xlims = (-0.6, 0.6)
plotter_ylims = (-0.6, 0.6)

# In the try catch block we determine if the user has passed any inputs. If so, parse the inputs and overwrite the previous variables.
# If not, error and end the program after printing instructions for how to pass inputs to the user. Include data types!
try
    global parameter_1, parameter_2
    parameter_1 = parse(Float64, replace(replace(split(ARGS[end])[1],"["=>""),"]"=>""))
    parameter_2 = parse(Int, replace(replace(split(ARGS[end])[1],"["=>""),"]"=>""))

catch
    println("\nPlease make the last argument to the command line a 2-value matrix with the height ∈[0.0, 1.0] of your circumelliptical arc, and the number of sides an Integer > 2, separated without a space. For example, julia ./solver.jl 2 6 \'[0.5 5]\'")
    exit()
end

# Here check if the passed inputs are subject to whatever conditions your module needs them to be. Again, error and end the program after printing instructions if not.
if parameter_1 > 1.0 || parameter_1 < 0.0 || parameter_2 < 2
    println("\nPlease make the last argument to the command line a 2-value matrix with the height ∈[0.0, 1.0] of your circumelliptical arc, and the number of sides an Integer > 2, separated without a space. For example, julia ./solver.jl 2 6 \'[0.5 5]\'")
    exit()
end

# Print back what the user has input so it is stored in the stdout/cluster manager's output.
println("Stretch value for vertical axis: ", parameter_1)
println("Number of sides: ", parameter_2)

# This is required for distributed (parallel processing) computing.
# This block makes sure each computer that will do any work knows the value of the variables.
# Make sure to include each variable!
if Distributed.nworkers() > 1
    for i = 2:nworkers()+1
        global parameter_1, parameter_2
        remotecall_fetch(()->parameter_1, i)
        remotecall_fetch(()->parameter_2, i)
    end
end

# This is where you define your "param", "dist", "find_diameter", and "magic_number" functions. See the readme for details.
# Make sure they're all wrapped in the Distributed.@everywhere block, again this is so each process doing work knows how to do that work.
# They don't have any particular order, except maybe dist and param. It shouldn't really matter.
Distributed.@everywhere begin

    # If you know the magic number of your space and want to compare the results with the solver, define it here.
    # This function must not take any arguments. Use globals if you need arguments.
    function magic_number()
        return 0.0
    end

    # If the diameter of your space is known beforehand, or there is a simple formula, define it here.
    # This function must not take any arguments. Use globals if you need arguments.
    # If this is not defined, at the end of script execution for solver.jl, a high precision run through of the metric
    # space will be performed to find the diameter instead. Having this function defined can speed things up.
    function find_diameter()
        return 1.0
    end

    # Here is where you define the parameterization of your function.
    # This should only accept an argument of a number between 0 and 1. If you still see this, then
    # I have not changed it to accept vector arguments for higher dimensions.
    # It must return an ordered pair.
    function param(x)
        global parameter_1
        return (cos(2*pi*x)/2.0, height*sin(2*pi*x)/2.0)
    end

    # Here is where you define the distance function.
    # Programmatically, the only rule that must be followed is that the input is a 1-d array and the output is a float.
    # For relevance to the math, just make sure it's symmetric (x[1] and x[2] could change places without changing the result)
    function dist(x)
        return sqrt((param(x[1])[1]-param(x[2])[1])^2+(param(x[1])[2]-param(x[2])[2])^2)
    end
end
