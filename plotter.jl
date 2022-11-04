using Plots
println("plotter.jl -- by Lukas Stuelke.\n")
metric_space_file = ""
if length(ARGS) > 0
    global metric_space_file
    metric_space_file = ARGS[1]
else
    global metric_space_file
    println("Please input path to a Julia script (\'module\') that defines your metric space information and parameterization.")
    println("This script must contain the following functions:")
    println("   1. param: (0,1)^n -> ℝ^(n+1), which parameterizes the unit interval into n+1 dimensional space.")
    println("   2. dist: (0,1)^2n -> ℝ+, which uses the parameterization to find the distance between two points.")
    println("This script may contain the following function:")
    println("   3. magic_number: ℤ+ ->  ℝ+, if the magic number has a known formula to compare results with.")
    print("\nEnter path to \'module\' script: ")
    metric_space_file = readline(stdin)
end
while isfile(metric_space_file) == false || metric_space_file[end-2:end] != ".jl"
    global metric_space_file
    println("Please input path to a Julia script (\'module\') that defines your metric space information and parameterization.")
    println("This script must contain the following functions:")
    println("   1. param: (0,1)^n -> ℝ^(n+1), which parameterizes the unit interval into n+1 dimensional space.")
    println("   2. dist: (0,1)^2n -> ℝ+, which uses the parameterization to find the distance between two points.")
    println("This script may contain the following function:")
    println("   3. magic_number: ℤ+ ->  ℝ+, if the magic number has a known formula to compare results with.")
    print("\nEnter path to \'module\' script: ")
    metric_space_file = readline(stdin)
end
println("Metric Space File = ", metric_space_file)
include(metric_space_file)
parameter_vals = [n/1000 for n = 0:1000]
x_points = [param(entry)[1] for entry in parameter_vals]
y_points = [param(entry)[2] for entry in parameter_vals]

plot_title =2
graphic = plot(x_points,
    y_points,
    title=string("Metric Space defined in ", metric_space_file),
    grid=true,
    gridalpha=0.9,
    minorgrid=true,
    minorgridalpha=0.5,
    linecolor=:red)
display(graphic)
readline()
