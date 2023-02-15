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
end
Base.broadcastable(S::TestSignal) = Ref(S)

function TestSignal(amp=1.0, freq=10.0, phase=0.0, offset=1.0)
    TestSignal(amp, freq, phase, offset)
end


(s::TestSignal)(t) = s.offset + s.amp * sin(2π * s.freq * t + s.phase)



mutable struct TestDaq <: AbstractInputDev
    "Device name"
    devname::String
    "Channel information"
    chans::DaqChannels{String}
    "Data acquisition Task"
    task::DaqTask
    "Coinfiguration"
    config::DaqConfig
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

    chans = DaqChannels(String[], "")
    task = DaqTask()
    rate = 100.0
    nsamples = 10
    config = DaqConfig(nsamples=Int64(nsamples),
                       rate=100.0)
    signal = TestSignal{Float64}[]
    E = zeros(0,0)
    return TestDaq(devname, chans, task, config, signal, E)
end

numchannels(dev::TestDaq) = numchannels(dev.chans)
daqchannels(dev::TestDaq) = daqchannels(dev.chans)




    
function daqaddinput(dev::TestDaq, chans::Vector{String}, signal::Vector{TestSignal{Float64}})

    if length(chans) != length(signal)
        error("Number of channels should be the same as the number of signals")
    end

    channels = DaqChannels(devname(dev), devtype(dev), chans, "", "")

    dev.chans = channels
    dev.signal = signal
    return
    
end

function daqaddinput(dev::TestDaq, chans::Vector{String};
                    amp=1.0, freq=10.0, offset=1.0)
    nch = length(chans)
    phase = range(0.0, 2π, length=nch+1)[1:end-1]
    signals = [TestSignal(amp, freq, ϕ, offset) for ϕ in phase]
    daqaddinput(dev, chans, signals)
end


function daqaddinput(dev::TestDaq, nchans::Integer;
                     channames="E", amp=1.0, freq=10.0, offset=1.0)
    nd = numdigits(nchans)
    chans = [string(channames, numstring(i, nd)) for i in 1:nchans]
    phase = range(0.0, 2π, length=nchans+1)[1:end-1]
    signals = [TestSignal(amp, freq, ϕ, offset) for ϕ in phase]
    
    return daqaddinput(dev, chans, signals)
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

    iparam!(dev.config, "nsamples", nsamples)
    fparam!(dev.config, "rate", rate)
    dev.E = zeros(numchannels(dev), nsamples)
    
    return
end


function filldata!(dev)
   
    nchans = numchannels(dev)

    rate = fparam(dev.config, "rate")
    nsamples = iparam(dev.config, "nsamples")

    tt = range(0.0, length=nsamples, step=1/rate)
    E = zeros(numchannels(dev), nsamples)
    dev.E = E
    for (k,t) in enumerate(tt)
        for i in 1:nchans
            E[i,k] = dev.signal[i](t)
        end
    end
    
end


function daqacquire(dev::TestDaq)

    dev.task.isreading && error("Already reading!")
    
    rate = fparam(dev.config, "rate")
    nsamples = iparam(dev.config, "nsamples")
    sampling = DaqSamplingRate(rate, nsamples, now())
    dev.task.isreading = true
    sleep(samplingperiod(sampling)) # Let's wait a while
    dev.task.isreading = false
    cleartask!(dev.task)
    filldata!(dev)
    println(typeof(sampling))
    return MeasData(devname(dev), devtype(dev), sampling, dev.E, dev.chans)
end


function daqstart(dev::TestDaq)

    dev.task.isreading && error("Already reading!")

    rate = fparam(dev.config, "rate")
    nsamples = iparam(dev.config, "nsamples")
    Δt = nsamples / rate  # Time to wait in seconds
    
    tinit = time_ns()
    dev.task.isreading = true
    dev.task.time = now()
    t =  @async sleep(Δt) 
    filldata!(dev)
    dev.task.timing = (tinit, tinit+1_000_000_000, 1)
    dev.task.task = t
    return t
end

function daqread(dev::TestDaq)
    
    if dev.task.isreading
        wait(dev.task.task)
    else
        error("Not reading anything")
    end
    
    rate = fparam(dev.config, "rate")
    nsamples = iparam(dev.config, "nsamples")

    dev.task.isreading = false
    cleartask!(dev.task)
    sampling = DaqSamplingRate(rate, nsamples, dev.task.time)
    return MeasData(devname(dev), devtype(dev), sampling, dev.E, dev.chans)
end


isreading(dev::TestDaq) = dev.task.isreading
samplesread(dev::TestDaq) =
    min(iparam(dev.config,"nsamples"),
        round(Int, (time_ns()-dev.task.timing[1])*1e-9 *
            fparam(dev.config, "rate")))

isdaqfinished(dev::TestDaq) = !isreading(dev)


    
