using ParallelProgressMeter
using Base.Test

if nprocs() <= 1
    addprocs(Sys.CPU_CORES)
end

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


c = RemoteChannel()

params = round(Int, 1e8)*ones(Int64, length(procs())-1)


@parallel (vcat) for i = 1:nprocs()-1
    serialTask(1, c, i, 1.0, true)
end


progressArray = zeros(Float64, nprocs()-1)


@async updateProgress!(c, progressArray, 1.0)

@parallel (vcat) for i = 1:nprocs()-1
    serialTask(params[i], c, i, 1.0, true)
end

close(c)
