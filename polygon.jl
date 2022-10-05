using BlackBoxOptim, Optim
println("There are ", Threads.nthreads(), " threads active.")
global n
n = 3

function magic_number(x)
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

function find_diameter(n)
    if n%2 == 0
        return 2.0
    end
    x = (n+n%2)/(2*n)
    x_b = ceil(x*n) # x between: x is this and the next vertex
    x_a = (x*n)%1 # x along: how far is x between them (%)
    return sqrt((1-cos((2*π*x_b-2*π)/n)*(1-x_a)-cos((2*π*x_b)/n)*x_a)^2 + (sin((2*π*x_b-2*π)/n)*(1-x_a)+sin((2*π*x_b)/n)*x_a)^2)
end

function param(x)
    global n
    pin = π/n
    x_f = 2*floor(x*n)+1
    return (1-cos(pin)*cos(pin*x_f)+(2*x*n-x_f)*sin(pin)*sin(pin*x_f), cos(pin)*sin(pin*x_f)+(2*x*n-x_f)*sin(pin)*cos(pin*x_f))
end

function dist(x)
    return sqrt((param(x[1])[1]-param(x[2])[1])^2+(param(x[1])[2]-param(x[2])[2])^2)
end

function find_max(points)
    function avg_dist(z)
        return -1.0*sum(dist([z[1], entry]) for entry in points)/length(points)
    end
    results = bboptimize(avg_dist, zeros(1).+0.5; SearchRange = (0.0, 1.0), NumDimensions=1, MaxSteps=5000, MaxTime=0.0, Method=:xnes, TraceMode=:silent)
    return -1*best_fitness(results)
end

function find_min(points)
    function avg_dist(z)
        return sum(dist([z[1], entry]) for entry in points)/length(points)
    end
    results = bboptimize(avg_dist, zeros(1).+0.5; SearchRange = (0.0, 1.0), NumDimensions=1, MaxSteps=5000, MaxTime=0.0, Method=:xnes, TraceMode=:silent)
    return -1*best_fitness(results)
end


lower = zeros(3)
upper = copy(lower).+1.0
initial_x = copy(lower).+0.5
results = Any[0.0 for i = 1:Threads.nthreads()]
timepassed = Any[0.0 for i = 1:Threads.nthreads()]
thisthread = Any[0 for i = 1:Threads.nthreads()]

upper_bound = Inf
lower_bound = -Inf
updating = true
function callbackmax(x)
    global upper_bound
    global lower_bound
    global updating
    if x.value < upper_bound && x.value > lower_bound && updating == true
        upper_bound = x.value
    elseif updating == false
        return true
    elseif x.value <= lower_bound
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
        lower_bound = -x.value
    elseif updating == false
        return true
    elseif -x.value >= upper_bound
        updating = false
        return true
    end
    return false
end

@sync begin
    global updating
    Threads.@threads for i = 1:Threads.nthreads()
        timepassed[i] = time()
        thisthread[i] = Threads.threadid()
        println("Thread ", Threads.threadid(), " has started.")
        temp_drop = 3
        width_drop = 4
        epsilon = 5
        verbos = 3
        iteration = 10000
        tolerance = 1e-5
        if i <= floor(Threads.nthreads()/2)
        results[i] = optimize(find_max, lower, upper, initial_x,
                              SAMIN(nt=temp_drop, ns= width_drop, neps=epsilon, verbosity=verbos),
                              Optim.Options(callback=callbackmax, allow_f_increases=true, successive_f_tol=100, g_tol=tolerance, iterations=iteration, show_trace=false))
        else
        results[i] = optimize(find_min, lower, upper, initial_x,
                            SAMIN(nt=temp_drop, ns= width_drop, neps=epsilon, verbosity=verbos),
                            Optim.Options(callback=callbackmin, allow_f_increases=true, successive_f_tol=100, g_tol=tolerance, iterations=iteration, show_trace=false))
        end
        timepassed[i] = time()-timepassed[i]
        println("Thread ", Threads.threadid(), " has finished after ", timepassed[i], " seconds.")
        updating = false
    end
end

println(" ")
for i = 1:Threads.nthreads()
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
print("Target Result = ", magic_number(n)*find_diameter(n))
if upper_bound >= magic_number(n)*find_diameter(n) && magic_number(n)*find_diameter(n) >= lower_bound
    println(", which is successfully inside of our interval!")
else
    println(", which is not inside of our interval.")
end
