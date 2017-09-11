using ParallelProgressMeter
using Base.Test

N = Int64(5e8)

if nprocs() > 1
    println("Reducing workers to 1")
    rmprocs(procs()[2:end])
end

println("")

println("Running parallel loop reduction test with one worker")

p = initializeProgress(N)

#the value being accumulated must be at the end of the loop code block but the next! line should 
#appear after the desired computation
a = @parallel (+) for i = 1:N
    tmp = rand()
    next!(p)
    tmp
end

if nprocs() < 4
    addprocs(4)
    println("Added 4 workers to test parallel loop")
end

#note that the package using command must be after adding workers and use the @everything tag so 
#the next! function is available on each worker
@everywhere using ParallelProgressMeter

println("")

println("Running parallel loop reduction test")
#p, idDict = initializeProgress(N)
p = initializeProgress(N)

#the value being accumulated must be at the end of the loop code block but the next! line should 
#appear after the desired computation
a = @parallel (+) for i = 1:N
    tmp = rand()
    next!(p)
    tmp
end

println(string("Summed a uniform (0, 1) random variable ", N, " times in parallel across ", nprocs()-1, " workers to a value of ", a))
