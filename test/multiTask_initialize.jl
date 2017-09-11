using ParallelProgressMeter
using Base.Test

numTasks = 4

addprocs(2)
#@everywhere using ParallelProgressMeter
println("Added 2 workers to test when number of tasks exceed number of workers")
println("")

#define a generic serial task that will be run in parallel once for each CPU core
#in order to push updates to the progressArray each serial task must have access to
#the shared array keeping track of progress and take the task number as input
@everywhere function serialTask1(N::Int64, taskNum::Int64, p::SharedArray{Int64, 1})
    a = 0.0
    for i = 1:N
        a += rand()
        p[taskNum] += 1
    end
    return a
end

#number of times each task will iterate, in this case every task 
#will perform 1e8 iterations
params = round(Int, 5e8)*ones(Int64, numTasks)

println(string("Starting parallel for loop test with ", numTasks, " tasks across ", nprocs() - 1, " workers"))

#initialize parallel progress monitor and save shared array
p = initializeProgress(numTasks, params)

#run parallel for loop with progress meter
@parallel (vcat) for i = 1:numTasks
    serialTask1(params[i], i, p)
end

#add 2 more workers
addprocs(2)
#@everywhere using ParallelProgressMeter
println("Added 2 more workers to test when all tasks can be run in parallel")
println("")

#define a generic serial task that will be run in parallel once for each CPU core
#in order to push updates to the progressArray each serial task must have access to
#the shared array keeping track of progress
@everywhere function serialTask2(N::Int64, taskNum::Int64, p::SharedArray{Int64, 1})
    a = 0.0
    for i = 1:N
        a += rand()
        p[taskNum] += 1
    end
    return a
end


println(string("Starting parallel for loop test with ", numTasks, " tasks across ", nprocs() - 1, " workers"))

#initiaalize parallel progress monitor and save remote channel
p = initializeProgress(numTasks, params)

#run parallel for loop with progress meter
@parallel (vcat) for i = 1:numTasks
    serialTask2(params[i], i, p)
end
