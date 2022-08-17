using Dates

export TestDaq, TestSignal


struct TestSignal{T}
    "Amplitude of the signal"
    amp::T
    "Frequency in Hz of the signal"
    freq::T
    "Phase in rad of the signal"
    phase::T
    "Mean value offset of the signal"
    offset::T
    function TestSignal{T}(amp=1.0, freq=10.0, phase=0.0, offset=1.0) where {T}
        new(amp, freq, phase, offset)
    end
end
Base.broadcastable(S::TestSignal) = Ref(S)

TestSignal() = TestSignal{Float64}()

(s::TestSignal)(t) = s.offset + s.amp * sin(2π * s.freq * t + s.phase)



mutable struct TestDaq <: AbstractInputDev
    "Device name"
    devname::String
    "Channel information"
    chans::DaqChannels{String}
    "Data acquisition Task"
    task::DaqTask
    "Sampling rate"
    rate::Float64
    "Number of samples that should be acquired"
    nsamples::Int
    "Parameters to generate trigonometric signals on each channel"
    signal::Vector{TestSignal{Float64}}
    "Buffer to store the data"
    E::Matrix{Float64}
end

devname(dev::TestDaq) = dev.devname
devtype(dev::TestDaq) = "TestDaq"

"""
`TestDaq(devname, nchans; channames="E")`

Creates a test device, useful for testing stuff.
"""
function TestDaq(devname)

    chans = DaqChannels(devname, "TestDaq", String[])
    task = DaqTask()
    rate = 100.0
    nsamples = 10
    signal = TestSignal{Float64}[]
    E = zeros(0,0)
    return TestDaq(devname, chans, task, rate, nsamples, signal, E)
end

numchannels(dev::TestDaq) = numchannels(dev.chans)
daqchannels(dev::TestDaq) = daqchannels(dev.chans)




    
function daqaddinput(dev::TestDaq, chans::Vector{String}, signal::Vector{TestSignal{Float64}})

    if length(chans) != length(signal)
        error("Number of channels should be the same as the number of signals")
    end

    channels = DaqChannels(devname(dev), devtype(dev), chans, "")

    dev.chans = channels
    dev.signal = signal
    return
    
end

daqddinput(dev::TestDaq, chans::Vector{String}) =
    daqaddinput(dev, chans, [TestSignal() for i in 1:length(chans)])


function daqaddinput(dev::TestDaq, nchans::Integer, signal::Vector{TestSignal{Float64}};
                     channames="E")
    nd = numdigits(nchans)
    chans = [string(channames, numstring(i, nd)) for i in 1:nchans]
    return daqaddinput(dev, chans, signal)
end

function daqaddinput(dev::TestDaq, nchans::Integer; channames="E")
    nd = numdigits(nchans)
    chans = [string(channames, numstring(i, nd)) for i in 1:nchans]
    signal = [TestSignal{Float64}() for i in 1:nchans]
    return daqaddinput(dev, chans, signal)
end

                 

function daqconfig(dev::TestDaq; kw...)

    if haskey(kw, :rate) && haskey(kw, :dt)
        error("Parameters `rate` and `dt` can not be specified simultaneously!")
    elseif haskey(kw, :rate) || haskey(kw, :dt)
        if haskey(kw, :rate)
            rate = kw[:rate]
        else
            dt = kw[:dt]
            rate = 1.0 / dt
        end
    else
        error("Either `rate` or `dt` should be specified!")
    end
    
    
    if haskey(kw, :nsamples) && haskey(kw, :time)
        error("Parameters `nsamples` and `time` can not be specified simultaneously!")
    elseif haskey(kw, :nsamples) || haskey(kw, :time)
        if haskey(kw, :nsamples)
            nsamples = kw[:nsamples]
        else
            tt = kw[:time]
            nsamples = round(Int, tt * rate)
        end
    else
        error("Either `nsamples` or `time` should be specified")
    end

    dev.rate = rate
    dev.nsamples = nsamples
    
    dev.E = zeros(numchannels(dev), nsamples)
    
    return
end


function filldata!(dev)

    
    nchans = numchannels(dev)
    tt = range(0.0, length=dev.nsamples, step=1/dev.rate)
    E = zeros(numchannels(dev), dev.nsamples)
    dev.E = E
    for (k,t) in enumerate(tt)
        for i in 1:nchans
            E[i,k] = dev.signal[i](t)
        end
    end
    
end


function daqacquire(dev::TestDaq)
    tdaq = now()
    filldata!(dev)
    return MeasData(devname(dev), devtype(dev), tdaq, dev.rate, dev.E,
                    dev.chans.chanmap, nothing)
end


function daqstart(dev::TestDaq)
    t =  @async readtestsamples(dev)
    dev.task.time = now()
    t1 = now()
    dev.task.timing = (t1, t1+1, 1)
    dev.task.task = t
    return t
end

function daqread(dev::TestDaq)

    wait(dev.tsk)
    dev.task.timing = (dev.task.timing[1], time_ns(), dev.nsamples)
    dev.task.isreading = false
    return MeasData(devname(dev), devtype(dev), dev.task.time,
                    dev.rate, dev.E, dev.chans)
end


isreading(dev::TestDaq) = dev.task.isreading
samplesread(dev::TestDaq) =
    min(dev.nsamples, round(Int, (time_ns()-dev.timing[1])*1e-9 * dev.rate))
isdaqfinished(dev::TestDaq) = !isreading(dev)


    
