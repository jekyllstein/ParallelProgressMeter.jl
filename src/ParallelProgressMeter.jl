__precompile__()

module ParallelProgressMeter

export initializeProgress

#copied from https://github.com/timholy/ProgressMeter.jl
function move_cursor_up_while_clearing_lines(io, numlinesup)
    [print(io, "\u1b[1G\u1b[K\u1b[A") for _ in 1:numlinesup]
end

#copied from https://github.com/timholy/ProgressMeter.jl
function printover(io::IO, s::AbstractString, color::Symbol = :color_normal)
    if isdefined(Main, :IJulia) || isdefined(Main, :ESS) || isdefined(Main, :Atom)
        print(io, "\r" * s)
    else
        print(io, "\u1b[1G")   # go to first column
        print_with_color(color, io, s)
        print(io, "\u1b[K")    # clear the rest of the line
    end
end

function monitorProgress!(c::RemoteChannel{Channel{Any}}, progressArray::Array{Float64,1}, delay::Float64 = 1.0)
#update progressArray as workers send updates to channel with a default delay of 1 second    
    t = time()
    #for x in c
    try

        for a in 1:length(progressArray)
            println(string("Progress of task ", a, " is 0.00 %"))
            #println("")
            #printover(STDOUT, string("Progress of task ", a, " is ", round(progressArray[a], 2), "%"))
        end
        while true
            currentUpdate = take!(c)
            id = currentUpdate[1]
            progress = currentUpdate[2]
            progressArray[currentUpdate[1]] = currentUpdate[2]
            if (time() - t) > delay
                    move_cursor_up_while_clearing_lines(STDOUT, length(progressArray))
                for a in 1:length(progressArray)
                    println(string("Progress of task ", a, " is ", round(progressArray[a], 2), "%"))
                    #printover(STDOUT, string("Progress of task ", a, " is ", round(progressArray[a], 2), "%"))
                end
                t = time()
            end
        end
    catch 
        #when remote channel is closed this expression will execute
        move_cursor_up_while_clearing_lines(STDOUT, length(progressArray))
        for a in 1:length(progressArray)
            println(string("Progress of task ", a, " is ", round(progressArray[a], 2), "%"))
        end
        println("Parallel progress monitor complete")
        println("")
    end
end

function initializeProgress(numTasks::Int64, delay::Float64 = 1.0)
#initializes progressArray and remote channel, starts running updateProgress!
#asynchronously, and returns remote channel for later use.  numTasks should match
#the number of tasks run in the parallel for loop.  If nprocs() does not exceed numTasks
#by 1 will addprocs until that is the case.
    
    if numTasks > nprocs()
        println(string("Warning: number of parallel tasks is greater than or equal to the ", nprocs(), " workers"))
        println("For a parallel for loop it is recommended to have a worker added for each parallel task in addition to the primary worker launching the loop")
    end

    if numTasks > Sys.CPU_CORES
        println(string("Warning: number of parallel tasks exceeds the ", Sys.CPU_CORES, " available cores"))
    end
    
    progArray = zeros(Float64, numTasks)
    c = RemoteChannel()

    #initialize update monitor that will record and print the progress of
    #each serial task
    @async monitorProgress!(c, progArray, delay)

    return c
end

end # module
