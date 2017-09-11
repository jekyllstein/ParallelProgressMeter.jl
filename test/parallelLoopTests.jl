#using ParallelProgressMeter
using Base.Test

addprocs(1)
@everywhere using ParallelProgressMeter
##----------------------------------Parameters for multitask test-----------------------------------------
numTasks = 4
#number of times each task will iterate, in this case every task 
#will perform 5e8 iterations
params = round(Int, 5e8)*ones(Int64, numTasks)
#---------------------------------------------------------------------------------------------------------

##-----------------------------------Parameters for single task test--------------------------------------
N = Int64(5e8)
#---------------------------------------------------------------------------------------------------------

##----------------------------------Tests with just one added worker--------------------------------------------

##Multiple task test
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

@everywhere function serialTaskLean1(N::Int64)
    a = 0.0
    for i = 1:N
        a += rand()
    end
    return a
end

println(string("Starting parallel for loop test with ", numTasks, " tasks across 1 worker"))

#initialize parallel progress monitor and save shared array
p = initializeProgress(numTasks, params)

#run parallel for loop with progress meter
@parallel (vcat) for i = 1:numTasks
    serialTask1(params[i], i, p)
end

println("Multi task run without progress meter")
#run parallel for loop without
@time @parallel (vcat) for i = 1:numTasks
    serialTaskLean1(params[i])
end

##Single task test

println("")
println(string("Starting parallel for loop test for a single task with ", N, " iterations across 1 worker"))
p = initializeProgress(N)

#the value being accumulated must be at the end of the loop code block but the next! line should 
#appear after the desired computation
a = @parallel (+) for i = 1:N
    tmp = rand()
    next!(p)
    tmp
end

println(string("Summed a uniform (0, 1) random variable ", N, " times in parallel across 1 worker to a value of ", a))
println("")

println("Single task run without progress meter")
@time a = @parallel (+) for i = 1:N
    tmp = rand()
end

println("")
##--------------------------------------------------------------------------------------------------------
addprocs(3)
@everywhere using ParallelProgressMeter
println("Adding 3 additional workers and initializing package on them")

##----------------------------------Tests with 4 added workers--------------------------------------------


##Multiple task test
println("")
#define a generic serial task that will be run in parallel once for each CPU core
#in order to push updates to the progressArray each serial task must have access to
#the shared array keeping track of progress and take the task number as input
@everywhere function serialTask2(N::Int64, taskNum::Int64, p::SharedArray{Int64, 1})
    a = 0.0
    for i = 1:N
        a += rand()
        p[taskNum] += 1
    end
    return a
end

@everywhere function serialTaskLean2(N::Int64)
    a = 0.0
    for i = 1:N
        a += rand()
    end
    return a
end

println(string("Starting parallel for loop test with ", numTasks, " tasks across ", nprocs() -1, " workers"))

#initialize parallel progress monitor and save shared array
p = initializeProgress(numTasks, params)

#run parallel for loop with progress meter
@parallel (vcat) for i = 1:numTasks
    serialTask2(params[i], i, p)
end

println("Multi task run without progress meter")
#run parallel for loop without
@time @parallel (vcat) for i = 1:numTasks
    serialTaskLean2(params[i])
end

##Single task test

println("")
println(string("Starting parallel for loop test for a single task with ", N, " iterations across ", nprocs() - 1, " workers"))
p = initializeProgress(N)

#the value being accumulated must be at the end of the loop code block but the next! line should 
#appear after the desired computation
a = @parallel (+) for i = 1:N
    tmp = rand()
    next!(p)
    tmp
end

println(string("Summed a uniform (0, 1) random variable ", N, " times in parallel across ", nprocs() - 1, " workers to a value of ", a))

println("Single task run without progress meter")
@time a = @parallel (+) for i = 1:N
    tmp = rand()
end

println("")

##--------------------------------------------------------------------------------------------------------
addprocs(Sys.CPU_CORES)
@everywhere using ParallelProgressMeter
println(string("Adding ", Sys.CPU_CORES, " additional workers and initializing package on them"))

##----------------------------------Tests with number of CPU cores as added workers--------------------------------------------

##Multiple task test
println("")
#define a generic serial task that will be run in parallel once for each CPU core
#in order to push updates to the progressArray each serial task must have access to
#the shared array keeping track of progress and take the task number as input
@everywhere function serialTask3(N::Int64, taskNum::Int64, p::SharedArray{Int64, 1})
    a = 0.0
    for i = 1:N
        a += rand()
        p[taskNum] += 1
    end
    return a
end

@everywhere function serialTaskLean3(N::Int64)
    a = 0.0
    for i = 1:N
        a += rand()
    end
    return a
end

println(string("Starting parallel for loop test with ", numTasks, " tasks across ", nprocs() -1, " workers"))

#initialize parallel progress monitor and save shared array
p = initializeProgress(numTasks, params)

#run parallel for loop with progress meter
@parallel (vcat) for i = 1:numTasks
    serialTask3(params[i], i, p)
end

println("Multi task run without progress meter")
#run parallel for loop without
@time @parallel (vcat) for i = 1:numTasks
    serialTaskLean3(params[i])
end

##Single task test

println("")
println(string("Starting parallel for loop test for a single task with ", N, " iterations across ", nprocs() - 1, " workers"))
p = initializeProgress(N)

#the value being accumulated must be at the end of the loop code block but the next! line should 
#appear after the desired computation
a = @parallel (+) for i = 1:N
    tmp = rand()
    next!(p)
    tmp
end

println(string("Summed a uniform (0, 1) random variable ", N, " times in parallel across ", nprocs() - 1, " workers to a value of ", a))

println("Single task run without progress meter")
@time a = @parallel (+) for i = 1:N
    tmp = rand()
end
