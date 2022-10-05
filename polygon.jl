using BlackBoxOptim, Optim
println("There are ", Threads.nthreads(), " threads active.")
println("Simulation launched. Searching for input text file...")
global parameters
parameters = Any[]

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
parameter_texts = ["Number of sides", # Line 1
                   "Number of points", # Line 2
                   "Avg. Dist. Extrema Max Iterations", # Line 3
                   "Avg. Dist. Extrema Selected Max Time", # Line 4
                   "Avg. Dist. Extrema Selected Method", # Line 5
                   "Avg. Dist. Extrema Convergence Tolerance", # Line 6
                   "Avg. Dist. Extrema Console Output Level", # Line 7
                   "Point Location Max Iterations", # Line 8
                   "Point Location Max Time", # Line 9
                   "Point Location Temperature Drop", # Line 10
                   "Point Location Boundary Shrink", # Line 11
                   "Point Location Past Best Point Memory Amount", # Line 12
                   "Point Location Convergence Tolerance", # Line 13
                   "Point Location Console Output Level"] # Line 14

parameter_types = ["(Int > 2)",
                   "(Int)",
                   "(Int)",
                   "(Float)",
                   "(Int)",
                   "(Float)",
                   "(0 - Silent, 1 - Compact, 2 - Verbose)",
                   "(Int)",
                   "(Float)",
                   "(Int)",
                   "(Int)",
                   "(Int)",
                   "(Float)",
                   "(0 - Silent, 1 - Compact, 2 - Normal, 3 - Verbose)"]

try # This entire try statement just loads saved data/user input.
    saved = open("inputs.txt")
    a = readline(saved)
    while length(a) > 0 && length(parameters) < length(parameter_texts)
        b = grab(a)

        push!(parameters, b)
        a = readline(saved)
    end
    if length(parameters) != length(parameter_texts)
        throw(DimensionMismatch(["Too many or not enough saved parameters."]))
    end
    println("\nSaved parameters found:\n")
    for i = 1:length(parameters)
        if i != 5 && i != 7
            println(parameter_texts[i], ": ", parameters[i])
        elseif i == 5
            println(parameter_texts[i], ": ", optimizer(parameters[i]))
        elseif i == 7
            println(parameter_texts[i], ": ", output_level(parameters[i]))
        end
    end
    println("To continue with these settings, leave the input blank and hit enter. Otherwise, type anything and hit enter.")
    a = readline(stdin)
    if length(a) > 0
        throw(SystemError[])
    end
catch
    println("Please fill out simulation details:\n")
    for i = 1:length(parameter_texts)
        if i != 5
            print(parameter_texts[i], " ", parameter_types[i], ": ")
        elseif i == 5
            println(" ")
            for j = 1:1:14
                println(j, " - ", optimizer(j))
            end
            print("\n", parameter_texts[i], " ", parameter_types[i], ": ")
        end
        a = readline(stdin)
        b = grab(a)
        while i == 1 && (typeof(b) != Int || b < 3)
            println("\nPlease type an integer greater than 2.")
            print(parameter_texts[i], " ", parameter_types[i], ": ")
            a  = readline(stdin)
            b = grab(a)
        end
        while (i == 2 || i == 3 || i == 5 || i == 7 || i == 8 || i == 10 || i == 11 || i == 12 || i == 14) && typeof(b) != Int
            println("\nPlease type an integer (no decimal points).")
            print(parameter_texts[i], " ", parameter_types[i], ": ")
            a  = readline(stdin)
            b = grab(a)
        end
        while (i == 4 || i == 6 || i == 9 || i == 13) && supertype(typeof(b)) != AbstractFloat
            println("\nPlease type a float (has decimal points).")
            print(parameter_texts[i], " ", parameter_types[i], ": ")
            a  = readline(stdin)
            b = grab(a)
            println(typeof(b))
            println(supertype(typeof(b)))
        end
        parameters[i] = b
    end
end
println("Saving settings...")
a = open("inputs.txt", write=true) do io
    for entry in parameters
        println(io, string(entry))
    end
end

function magic_number(x) # Calculates the magic number of a regular polygon for comparison to optimizer's results.
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

function find_diameter(n) # Finds the diameter of a regular polygon using symmetries.
    if n%2 == 0
        return 2.0
    end
    x = (n+n%2)/(2*n)
    x_b = ceil(x*n) # x between: x is this and the next vertex
    x_a = (x*n)%1 # x along: how far is x between them (%)
    return sqrt((1-cos((2*π*x_b-2*π)/n)*(1-x_a)-cos((2*π*x_b)/n)*x_a)^2 + (sin((2*π*x_b-2*π)/n)*(1-x_a)+sin((2*π*x_b)/n)*x_a)^2)
end

function param(x) # Parameterizes the unit interval into a regular polygon.
    global parameters
    n = parameters[1]
    pin = π/n
    x_f = 2*floor(x*n)+1
    return (1-cos(pin)*cos(pin*x_f)+(2*x*n-x_f)*sin(pin)*sin(pin*x_f), cos(pin)*sin(pin*x_f)+(2*x*n-x_f)*sin(pin)*cos(pin*x_f))
end

function dist(x) # Finds the euclidean distance of two points on the unit interval after paramaterization above.
    return sqrt((param(x[1])[1]-param(x[2])[1])^2+(param(x[1])[2]-param(x[2])[2])^2)
end

function find_max(points) # Finds the maximum of the range of the average distance function.
    global parameters
    function avg_dist(z) # Defines the local average distance function (necessary due to how the optimizer takes inputs).
        return -1.0*sum(dist([z[1], entry]) for entry in points)/length(points)
    end
    results = bboptimize(avg_dist, zeros(1).+0.5; SearchRange = (0.0, 1.0), NumDimensions=1, MaxSteps=parameters[3], MaxTime=parameters[4], Method=optimizer(parameters[5]), FitnessTolerance=parameters[6], TraceMode=output_level(parameters[7]))
    return -1*best_fitness(results)
end

function find_min(points) # Finds the minimum of the range of the average distance function.
    global parameters
    function avg_dist(z) # Local avg distance function.
        return sum(dist([z[1], entry]) for entry in points)/length(points)
    end
    results = bboptimize(avg_dist, zeros(1).+0.5; SearchRange = (0.0, 1.0), NumDimensions=1, MaxSteps=parameters[3], MaxTime=parameters[4], Method=optimizer(parameters[5]), FitnessTolerance=parameters[6], TraceMode=output_level(parameters[7]))
    return -1*best_fitness(results)
end

lower = zeros(parameters[2]) # Our lower bounds are always zero. The number of points determines the vector length.
upper = copy(lower).+1.0 # Upper bounds are always 1.
initial_x = copy(lower).+0.5 # Initial point locations. An educated guess might determine how we initialize points.
timepassed = Any[0.0 for i = 1:Threads.nthreads()] # Measure computer time for benchmarking.
thisthread = Any[0 for i = 1:Threads.nthreads()] # For benchmarking purposes.

upper_bound = Inf # The upper bound should shrink and shrink, so initialize at infinity.
lower_bound = -Inf # Likewise.
updating = true # Determines when to tell other threads to stop computing.
function callbackmax(x) # Determines when to tell other threads to stop computing.
    global upper_bound
    global lower_bound
    global updating
    if x.value < upper_bound && x.value > lower_bound && updating == true
        upper_bound = x.value # If we've shrunk the upper bound, update the variable.
    elseif updating == false
        return true
    elseif x.value <= lower_bound # However, if we've gone below the lower bound, halt computation.
        updating = false
        return true
    end
    return false
end

function callbackmin(x)
    global upper_bound
    global lower_bound
    global updating
    if -x.value > lower_bound && -x.value < upper_bound && updating == true
        lower_bound = -x.value # If we've raised the lower bound, update.
    elseif updating == false
        return true
    elseif -x.value >= upper_bound # Likewise, stop if we've passed the upper bound.
        updating = false
        return true
    end
    return false
end

if Threads.nthreads() > 1 # Do parallel computation if we're allowed more than one thread.
    results = Any[0.0 for i = 1:Threads.nthreads()]
    @sync begin # Don't leave this block until all threads are finished.
        global updating
        global parameters
        Threads.@threads for i = 1:Threads.nthreads()
            timepassed[i] = time()
            thisthread[i] = Threads.threadid()
            println("Thread ", Threads.threadid(), " has started.")
            temp_drop = parameters[10]
            width_drop = parameters[11]
            epsilon = parameters[12]
            verbos = parameters[14]
            iteration = parameters[8]
            tolerance = parameters[13]
            if i <= floor(Threads.nthreads()/2) # Split computation of mins/maxs evenly. When (god knows why) we have an odd # of threads, do 1 more minimum calc. No particular reason.
            results[i] = optimize(find_max, lower, upper, initial_x,
                                SAMIN(nt=temp_drop, ns= width_drop, neps=epsilon, verbosity=verbos),
                                Optim.Options(time_limit=parameters[9], callback=callbackmax, allow_f_increases=true, successive_f_tol=100, g_tol=tolerance, iterations=iteration, show_trace=false))
            else
            results[i] = optimize(find_min, lower, upper, initial_x,
                                SAMIN(nt=temp_drop, ns= width_drop, neps=epsilon, verbosity=verbos),
                                Optim.Options(time_limit=parameters[9], callback=callbackmin, allow_f_increases=true, successive_f_tol=100, g_tol=tolerance, iterations=iteration, show_trace=false))
            end
            timepassed[i] = time()-timepassed[i]
            println("Thread ", Threads.threadid(), " has finished after ", timepassed[i], " seconds.")
            updating = false
        end
    end
else # when we only have one thread, do both calculations in sequence.
    println("Calculation has started.")
    results = Any[0.0 for i = 1:2]
    timepassed[1] = time()
    thisthread[1] = 1
    temp_drop = parameters[10]
    width_drop = parameters[11]
    epsilon = parameters[12]
    verbos = parameters[14]
    iteration = parameters[8]
    tolerance = parameters[13]
    results[1] = optimize(find_max, lower, upper, initial_x,
                        SAMIN(nt=temp_drop, ns= width_drop, neps=epsilon, verbosity=verbos),
                        Optim.Options(time_limit=parameters[9], callback=callbackmax, allow_f_increases=true, successive_f_tol=100, g_tol=tolerance, iterations=iteration, show_trace=false))
    results[2] = optimize(find_min, lower, upper, initial_x,
                        SAMIN(nt=temp_drop, ns= width_drop, neps=epsilon, verbosity=verbos),
                        Optim.Options(time_limit=parameters[9], callback=callbackmin, allow_f_increases=true, successive_f_tol=100, g_tol=tolerance, iterations=iteration, show_trace=false))
    timepassed[1] = time()-timepassed[1]
    println("Calculation finished after ", timepassed[1], " seconds.")
end
println(" ")
for i = 1:Threads.nthreads() # Print out the results of our calculations, some benchmarking, and comparison to known value.
    println(" ")
    print("Results for thread ", thisthread[i])
    if i <= floor(Threads.nthreads()/2)
        println(", minimizing the maximum.")
    else
        println(", maximizing the minimum.")
    end
    println("Points (interval): ", Optim.minimizer(results[i]))
    println("Points (space): ", [param(x) for x in Optim.minimizer(results[i])])
    println("Value: ", abs(Optim.minimum(results[i])))
    println("Seconds taken to calculate: ", timepassed[i])
end
println(" ")
println("Upper Bound = ", upper_bound)
println("Lower Bound = ", lower_bound)
print("Target Result = ", magic_number(parameters[1])*find_diameter(parameters[1]))
if upper_bound >= magic_number(parameters[1])*find_diameter(parameters[1]) && magic_number(parameters[1])*find_diameter(parameters[1]) >= lower_bound
    println(", which is successfully inside of our interval!")
else
    println(", which is not inside of our interval.")
end
