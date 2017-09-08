__precompile__()

module ParallelProgressMeter

export updateProgress!

#copied from ProgressMeter.jl
function move_cursor_up_while_clearing_lines(io, numlinesup)
    [print(io, "\u1b[1G\u1b[K\u1b[A") for _ in 1:numlinesup]
end

#copied from ProgressMeter.jl
function printover(io::IO, s::AbstractString, color::Symbol = :color_normal)
    if isdefined(Main, :IJulia) || isdefined(Main, :ESS) || isdefined(Main, :Atom)
        print(io, "\r" * s)
    else
        print(io, "\u1b[1G")   # go to first column
        print_with_color(color, io, s)
        print(io, "\u1b[K")    # clear the rest of the line
    end
end

function updateProgress!(c::RemoteChannel{Channel{Any}}, progressArray::Array{Float64,1}, delay::Float64)
#update progressArray as workers send updates to channel    
    t = time()
    #for x in c
    try

        for a in 1:length(progressArray)
            println("")
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
        move_cursor_up_while_clearing_lines(STDOUT, length(progressArray))
        for a in 1:length(progressArray)
            println(string("Progress of task ", a, " is ", round(progressArray[a], 2), "%"))
        end
    end
end

end # module
