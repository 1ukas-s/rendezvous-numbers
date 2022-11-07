# rendezvous-numbers
Using optimizers to find rendezvous numbers of certain metric spaces.
To use, you must install Julia and use pkg to install Optim and BlackBoxOptim.

Afterward you need to create or input a path to a 'module' script that defines two or three things about a metric space, all wrapped in Distributed.@everywhere:
   1. param: (0,1)^n -> ℝ^(n+1), which parameterizes the unit interval into n+1 dimensional space.
   2. dist: (0,1)^2n -> ℝ+, which uses the parameterization to find the distance between two points.
This script may contain the following functions:
   3. find_diameter: no input -> ℝ+, a method of calculating the maximum distance between two points in your metric space.
        If this is not included, optimization will be used to find this value (Must be defined as a function, not a variable).
   4. magic_number: no input ->  ℝ+, if the magic number has a known formula to compare results with.
   
Please find pre-made modules in the 'modules' folder if examples are needed.

If you intend for your script to have a slightly modifiable parameter, for example the number of sides in a regular polygon, or the length of the semi-minor axis of an ellipse, the user can input a table during the command line execution of the script: "julia ./solver.jl 4 8 ./modules/<name>.jl '[Param1 Param2 Param3 ... ]'". This is necessary for compatibility with clustered computing and cluster managers, otherwise I'd use standard input. See pre-made modules for what to do and how to handle this input, and how to use the value in your module.

Finally, run solver.jl with 3 command line arguments: the number of cores to dedicate, the number of tasks, and the path to the module you want to run. These can be defined during the script's execution by users but not through cluster job managers, so this must be done e.g. "julia ./solver.jl 4 8 ./modules/reg_polygon.jl '[5]'" when submitting scripts to cluster job managers.

Alternatively, or once the solver has finished, you can use plotter.jl to visualize the metric space defined in your module with an optional command line argument to give it some points to plot. For example, suppose solver.jl found that [0.0, 0.3334, 0.6667] happened to be a solution, and you want to see what those values map to under your parameterization, you would run "julia ./plotter.jl ./modules/<name>.jl '[0.0, 0.3334, 0.6667]' '<module_argument>'". The plot will save itself as 'plot.pdf' upon completion.
   
We utilize BlackBoxOptim.jl in this script, whose licenses can be found below.

# BlackBoxOptim.jl
    Copyright (c) 2013-2021: Robert Feldt (robert.feldt@gmail.com)

    Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
