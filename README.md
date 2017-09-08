# ParallelProgressMeter

[![Build Status](https://travis-ci.org/JasonEckstein/ParallelProgressMeter.jl.svg?branch=master)](https://travis-ci.org/JasonEckstein/ParallelProgressMeter.jl)

[![Coverage Status](https://coveralls.io/repos/JasonEckstein/ParallelProgressMeter.jl/badge.svg?branch=master&service=github)](https://coveralls.io/github/JasonEckstein/ParallelProgressMeter.jl?branch=master)

[![codecov.io](http://codecov.io/github/JasonEckstein/ParallelProgressMeter.jl/coverage.svg?branch=master)](http://codecov.io/github/JasonEckstein/ParallelProgressMeter.jl?branch=master)

Parallel progress meter for long running serial tasks being executed in a parallel for loop in Julia

## Usage

### Progress for N serial tasks with a pre-determined number of steps for each task

The current implementation only works for @parallel for loops that execute some function
serialTask() with certain required inputs.  A progress percentage will be shown for each 
parallel task running.  An example of how to use it copied from PMAP_tests.jl and executes
one serial task for each CPU core:
 
```julia
using ParallelProgressMeter

if nprocs() <= 1
    addprocs(Sys.CPU_CORES)
    println(string("Added ", nprocs()-1, " workers based on available CPU cores"))
end

#the parallel loop will execute one fewer tasks than the available cores
#the remaining core will in parallel monitor the progress of the others and
#accumulate any results
numTasks = nprocs()-1

#define a generic serial task that will be run in parallel once for each CPU core
#in order to push updates to the progressArray each serial task must have access to
#the remote channel listening for updates as be tagged with it's id in the parallel loop
@everywhere function serialTask(N::Int64, c::RemoteChannel{Channel{Any}}, id, delay::Float64, show = false)
    a = 0.0
    t = time()
    for i = 1:N
        a += rand()
        
        #if show && (((time() - t) > delay) || (i == N))
        if show && (((time() - t) > delay) || ((i == N) && (i != 1)))
        
            put!(c, (id, 100*i/N))
            #println(string("Progress = ", round(100*i/N, 2), "%"))
            t  = time()
        end
        
    end
    #put!(c, (id, 100.0))
    

    return a
end

#create a remote channel to listen for updates
c = RemoteChannel()

#number of times each task will iterate, in this case every task 
#will perform 1e8 iterations
params = round(Int, 1e8)*ones(Int64, numTasks)


# @parallel (vcat) for i = 1:nprocs()-1
#     serialTask(1, c, i, 1.0, true)
# end

#define array to track the progress of each serial task
progressArray = zeros(Float64, numTasks)

#initialize update monitor that will record and print the progress of
#each serial task
@async updateProgress!(c, progressArray, 1.0)

println(string("Starting parallel for loop test across ", numTasks, " workers"))

#run parallel for loop with progress meter
@parallel (vcat) for i = 1:numTasks
    serialTask(params[i], c, i, 1.0, true)
end

close(c)
```

## Notes
The current package can only be used in the narrow use case shown above and used for package testing.  Future plans include streamlining
the initialization process to one step, simplifying the requirements on serialTask to push updates to the progress array, and adding more 
display options.

Another version of parallelism in which a single parallel loop with a set number of steps is possible but not yet implemented.  That type of 
meter would only have one progress bar like the original package but would work on parallel loops instead of purely serial ones.

## Credits
Structure inspired by the package ProgressMeter.jl.  Basic parallel functionality created by Jason Eckstein @jekyllstein and Michael Jin @mikhail-j