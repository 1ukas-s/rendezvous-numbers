using Distributed
println("solver.jl -- by Lukas Stuelke.\n")
tasks = 0
cores = 0
metric_space_file = ""
if length(ARGS) > 0
    global tasks
    tasks = parse(Int, ARGS[1])
else
    global tasks
    print("Number of dedicated tasks: ")
    tasks = parse(Int, readline(stdin))
end
if length(ARGS) > 0
    global cores
    cores = parse(Int, ARGS[2])
else
    global cores
    print("Number of dedicated cores: ")
    cores = parse(Int, readline(stdin))
end
while isa(tasks, Signed) == false || isa(cores, Signed) == false || tasks*cores < 2
    global tasks, cores
    println("Tasks*Cores must be at least 2.")
    print("Number of dedicated tasks: ")
    tasks = parse(Int, readline(stdin))
    print("Number of dedicated cores: ")
    cores = parse(Int, readline(stdin))
end
if length(ARGS) > 2
    global metric_space_file
    metric_space_file = ARGS[3]
else
    global metric_space_file
    println("Please input path to a Julia script (\'module\') that defines your metric space information and parameterization.")
    println("This script must contain the following functions, all wrapped in Distributed.@everywhere:")
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
    println("This script must contain the following functions, all wrapped in Distributed.@everywhere:")
    println("   1. param: (0,1)^n -> ℝ^(n+1), which parameterizes the unit interval into n+1 dimensional space.")
    println("   2. dist: (0,1)^2n -> ℝ+, which uses the parameterization to find the distance between two points.")
    println("This script may contain the following function:")
    println("   3. magic_number: ℤ+ ->  ℝ+, if the magic number has a known formula to compare results with.")
    print("\nEnter path to \'module\' script: ")
    metric_space_file = readline(stdin)
end
addprocs(tasks*cores)
println("There are ", tasks*cores, " workers.")
println("Simulation launched. Searching for input text file...")
println("View the readme file if you need help with INPUTS.")

include(metric_space_file)


Distributed.@everywhere begin
    using BlackBoxOptim

    function optimizer(n) # A function which outputs an optimizer as a result of user input.
        (n == 1 || n == "separable nes") && return :separable_nes
        (n == 2 || n == "xnes") && return :xnes
        (n == 3 || n == "dxnes") && return :dxnes
        (n == 4 || n == "adaptive de rand 1 bin") && return :adaptive_de_rand_1_bin
        (n == 5 || n == "adaptive de rand 1 bin radiuslimited") && return :adaptive_de_rand_1_bin_radiuslimited
        (n == 6 || n == "de rand 1 bin") && return :de_rand_1_bin
        (n == 7 || n == "de rand 1 bin radiuslimited") && return :de_rand_1_bin_radiuslimited
        (n == 8 || n == "de rand 2 bin") && return :de_rand_2_bin
    (n == 9 || n == "de rand 2 bin radiuslimited") && return :de_rand_2_bin_radiuslimited
    (n == 10 || n == "generating set search") && return :generating_set_search
    (n == 11 || n == "probabilistic descent") && return :probabilistic_descent
    (n == 12 || n == "resampling memetic search") && return :resampling_memetic_search
    (n == 13 || n == "resampling inheritance memetic search") && return :resampling_inheritance_memetic_search
    (n == 14 || n == "simultaneous perturbation stochastic approximation") && return :simultaneous_perturbation_stochastic_approximation
    return :random_search
    end

    function output_level(n) # Takes user input and outputs an option for console logging during optimization.
        n == 2 && return :verbose
        n == 1 && return :compact
        return :silent
    end

    global parameters
    parameters = Any[]
	function grab(x) # Takes saved data/user input and correctly changes its type.
		b = x
		try
			b = parse(Int, x)
		catch
			try
				b = parse(Float64, x)
			catch
				b = b
			end
		end
		return b
	end
	parameter_texts = ["Number of points", # Line 1
					"Avg. Dist. Extrema Max Iterations", # Line 2
					"Avg. Dist. Extrema Selected Max Time", # Line 3
					"Avg. Dist. Extrema Selected Method", # Line 4
					"Avg. Dist. Extrema Convergence Tolerance", # Line 5
					"Avg. Dist. Extrema Console Output Level", # Line 6
					"Point Location Max Iterations", # Line 7
					"Point Location Selected Max Time", # Line 8
					"Point Location Selected Method", # Line 9
					"Point Location Convergence Tolerance", # Line 10
					"Point Location Console Output Level"] # Line 11

	saved = open("INPUTS")
	a = readline(saved)
	while length(a) > 0 && length(parameters) < length(parameter_texts)
		global a
		b = grab(a)

		push!(parameters, b)
		a = readline(saved)
	end
	if length(parameters) != length(parameter_texts)
		println("INPUTS was not formatted properly.")
		throw(DimensionMismatch(["Too many or not enough saved parameters."]))
	end
end

Distributed.@spawnat :any begin
	println("\nInput Data:")
	for i = 1:length(parameters)
		if i != 4 && i != 6 && i != 9 && i != 11
			println(parameter_texts[i], ": ", parameters[i])
		elseif i == 4 || i == 9
			println(parameter_texts[i], ": ", optimizer(parameters[i]))
		elseif i == 6 || i == 11
			println(parameter_texts[i], ": ", output_level(parameters[i]))
		end
	end
end

sleep(0.1)

Distributed.@everywhere begin
    function find_min(points) # Finds the maximum of the range of the average distance function.
        function avg_dist(z) # Defines the local average distance function (necessary due to how the optimizer takes inputs).
            return sum(dist([z[1], entry]) for entry in points)/length(points)
        end
        results = bboptimize(avg_dist; SearchRange = (0.0, 1.0),
                            NumDimensions=1,
                            MaxSteps=parameters[2],
                            MaxTime=parameters[3],
                            Method=optimizer(parameters[4]),
                            FitnessScheme=ScalarFitnessScheme{true}(),
                            MinDeltaFitnessTolerance=parameters[5],
                            TraceMode=output_level(parameters[6]))
        return best_fitness(results)
    end

    function find_max(points)
        function avg_dist(z)
            return sum(dist([z[1], entry]) for entry in points)/length(points)
        end
        results = bboptimize(avg_dist; SearchRange = (0.0, 1.0),
                            NumDimensions=1,
                            MaxSteps=parameters[2],
                            MaxTime=parameters[3],
                            Method=optimizer(parameters[4]),
                            FitnessScheme=ScalarFitnessScheme{false}(),
                            MinDeltaFitnessTolerance=parameters[5],
                            TraceMode=output_level(parameters[6]))
        return best_fitness(results)
    end
end

do_max = @task begin
    global setup_max
    global results_max
    setup_max = bbsetup(find_max; SearchRange = (0, 1),
                NumDimensions=parameters[1],
                MinDeltaFitnessTolerance=parameters[10],
                MaxNumStepsWithoutFuncEvals=0,
                MaxSteps=parameters[7],
                Method=optimizer(parameters[9]),
                FitnessScheme=ScalarFitnessScheme{true}(),
                TraceMode=output_level(parameters[11]),
                Workers=workers()[1:Int(floor(length(workers())/2))])
    results_max = bboptimize(setup_max)
end

do_min = @task begin
    global setup_min
    global results_min
    setup_min = bbsetup(find_min; SearchRange = (0, 1),
                NumDimensions=parameters[1],
                MinDeltaFitnessTolerance=parameters[10],
                MaxNumStepsWithoutFuncEvals=0,
                MaxSteps=parameters[7],
                Method=optimizer(parameters[9]),
                FitnessScheme=ScalarFitnessScheme{false}(),
                TraceMode=output_level(parameters[11]),
                Workers=workers()[Int(1+floor(length(workers())/2)):end])
    results_min = bboptimize(setup_min)
end


schedule(do_max)
schedule(do_min)

wait(do_max)
wait(do_min)

if @isdefined(find_diameter) == false
    function find_diameter()
        return best_fitness(bboptimize(dist; SearchRange = (0.0, 1.0),
                        NumDimensions=2,
                        MaxSteps=25000,
                        MaxTime=0.0,
                        Method=:adaptive_de_rand_1_bin,
                        FitnessScheme=ScalarFitnessScheme{false}(),
                        MinDeltaFitnessTolerance=1.0e-40,
                        TraceMode=:silent,
                        Workers=workers()))
    end
end
diameter = find_diameter()
println("\nResults:\nMaximum Avg. Distance Function Minimizing Points (not parameterized): ", best_candidate(results_max))
println("Maximum Avg. Distance Function Minimizing Points: ", [param(entry) for entry in best_candidate(results_max)])
println("Minimized Max Avg. Distance (Rendezvous): ", best_fitness(results_max))
println("Minimized Max Avg. Distance (Magic): ", best_fitness(results_max)/diameter)

println("\nMinimum Avg. Distance Function Maximizing Points (not parameterized): ", best_candidate(results_min))
println("Minimum Avg. Distance Function Maximizing Points: ", [param(entry) for entry in best_candidate(results_min)])
println("Maximized Min Avg. Distance (Rendezvous): ", best_fitness(results_min))
println("Maximized Min Avg. Distance (Magic): ", best_fitness(results_min)/diameter)
if @isdefined(magic_number)
    println("\nmagic_number was defined, calculating target value...")
    println("\nTarget Value (Rendezvous): ", magic_number()*diameter)
    println("Target Value (Magic): ", magic_number())
end
