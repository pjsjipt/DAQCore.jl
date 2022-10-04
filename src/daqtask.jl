
export AbstractDaqTask, DaqTask, cleartask!, daqthread, setdaqthread!
export stoptask, stoptask!, samplingrate, settiming!, daqtask, setdaqtask!



"""
`DaqTasq`

Creates a structure that handles asynchronous data acquisition.

This structure stores the number of samples read and the general state of data 
acquisition. It also provides timing measurements so that sampling frequency
can estimated and the time and date when the task began. 

It also stores a `Task` object that might be used for asynchronous data acquisition.
"""
mutable struct DaqTask <: AbstractDaqTask
    "Number of frames read"
    nread::Int
    "Is the device reading frames?"
    isreading::Bool
    "Stop data acquisition?"
    stop::Bool
    "Are we using threads?"
    thrd::Bool
    "Initial time, end time (ns) and number of frames"
    timing::NTuple{3, UInt64}
    "Time the task started"
    time::DateTime
    "`Task` object executing the data acquisition"
    task::Task
    DaqTask() = new(0,false,false,false, (UInt64(0),UInt64(0),UInt64(0)),
                    now(), Task(()->0))
end




"""
`isreading(tsk)`

Is the daq device currently acquiring data?

See [`samplesread`](@ref) to see the number of samples already read.
"""
isreading(task::DaqTask) = task.isreading

"""
`samplesread(task::DaqTask)`

Number of samples read
"""
samplesread(task::DaqTask) = task.nread


"""
`cleartask!(task)`

Clear the buffer. Set the DaqTask parameters to null state. 
"""
function cleartask!(task::DaqTask)
    isreading(task) && error("Can not clear a task while it is reading!")
    
    task.isreading = false # Let's make sure...
    task.stop = false
    task.thrd = false
    task.nread = 0
    return
end



setdaqthread!(task::DaqTask, thrdstatus=false) = task.thrd=thrdstatus
daqthread(task::DaqTask) = task.thrd


setdaqtask!(task::DaqTask, jtsk::Task) = task.task = jtsk
daqtask(task::DaqTask) = task.task

stoptask(task::DaqTask) = task.stop
stoptask!(task::DaqTask, s=true) = task.stop = s



"""
    `samplingrate(task)`

    Returns the measured sampling rateuency achieved during data acquisition

"""
samplingrate(task::DaqTask) = task.timing[3] / (1e-9 * (task.timing[2] - task.timing[1]))

"""
`settiming!(task, t1, t2, n)`

Updates timing information on current data acquisition

 * `task` The `DaqTask` object
 * `t1` Initial time of data acquisition
 * `t2` Last time of data acquisition
 * `n` Number of samples read between `t1` and `t2`

"""
settiming!(task, t1, t2, n) = task.timing = (UInt64(t1), UInt64(t2), UInt64(n))





