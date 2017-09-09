using ParallelProgressMeter
using Base.Test

numTasks = 4

addprocs(2)
println("Added 2 workers to test when number of tasks exceed number of workers")
println("")

#define a generic serial task that will be run in parallel once for each CPU core
#in order to push updates to the progressArray each serial task must have access to
#the remote channel listening for updates as be tagged with it's id in the parallel loop
@everywhere function serialTask1(N::Int64, c::RemoteChannel{Channel{Any}}, id, delay::Float64, show = false)
    a = 0.0
    t = time()
    for i = 1:N
        a += rand()
        if show && (((time() - t) > delay) || ((i == N) && (i != 1)))
        
            put!(c, (id, 100*i/N))
            #println(string("Progress = ", round(100*i/N, 2), "%"))
            t  = time()
        end
        
    end
   
    return a
end

#number of times each task will iterate, in this case every task 
#will perform 1e8 iterations
params = round(Int, 1e8)*ones(Int64, numTasks)

println(string("Starting parallel for loop test with ", numTasks, " tasks across ", nprocs() - 1, " workers"))

#initiaalize parallel progress monitor and save remote channel
c = initializeProgress(numTasks)



#run parallel for loop with progress meter
@parallel (vcat) for i = 1:numTasks
    serialTask1(params[i], c, i, 1.0, true)
end

close(c)

# println("Completed test 1")
# println("")
# println("")
# println("")

#add 2 more workers
addprocs(2)
println("Added 2 more workers to test when all tasks can be run in parallel")
println("")

#define a generic serial task that will be run in parallel once for each CPU core
#in order to push updates to the progressArray each serial task must have access to
#the remote channel listening for updates as be tagged with it's id in the parallel loop
@everywhere function serialTask2(N::Int64, c::RemoteChannel{Channel{Any}}, id, delay::Float64, show = false)
    a = 0.0
    t = time()
    for i = 1:N
        a += rand()
        
        if show && (((time() - t) > delay) || ((i == N) && (i != 1)))
        
            put!(c, (id, 100*i/N))
            #println(string("Progress = ", round(100*i/N, 2), "%"))
            t  = time()
        end
        
    end

    return a
end


println(string("Starting parallel for loop test with ", numTasks, " tasks across ", nprocs() - 1, " workers"))

#initiaalize parallel progress monitor and save remote channel
c = initializeProgress(numTasks)

#run parallel for loop with progress meter
@parallel (vcat) for i = 1:numTasks
    serialTask2(params[i], c, i, 1.0, true)
end

close(c)