# This file describes the data acquisition functionality.
# Each input device can implement other functionality but the
# the DAQJulia uses this interface to do data acquisition.

export InputDev
export daqaddinput, daqacquire, daqstart, daqread, daqstop, daqreference
export daqconfig, daqconfigdev, daqzero, samplesread, isreading, issamplesavailable
export numchannels, daqchannels, daqpeek, daqunits


struct InputDev{Chans,Conf} <: AbstractInputDev
    devname::String
    devtype::String
    chans::Chans
    config::Conf
end

devname(dev::InputDev) = dev.devname
devtype(dev::InputDev) = dev.devtype

"""
`daqaddinput(dev, ...)`

Add channels that should be acquired.
"""
function daqaddinput end

"""
`daqacquire(dev)`

Start a synchronous data acquisition run.
"""
function daqacquire end
function daqacquire! end

"""
`daqstart(dev, ...)`

Initiate a data acquisition run asyncrhonously.
"""
function daqstart end

"""
`daqread(dev)`

Wait to finish the data acquisition run and return the data.
"""
function daqread end
function daqread! end


"""
`daqstop(dev)`

Stop asynchronous data acquisition.
"""
function daqstop end

"""
`daqreference(dev)`

Use a measurement point as a reference. Specific channels can be specified.

"""
function daqreference end

"""
`daqconfig(dev; rate, nsamples, time, avg=1)`

Generic configuration of data acquisition. Different devices might
have other capabilities and different terminologies. To use the device specific
parameters and terminology, use function [`daqconfigdev`](@ref). 

In this generic interface, the following keyword parameters are allowed:

 * `rate` or `dt` (only one of them)
    - `rate` Sampling rate in Hz
    - `dt` Sampling time in s
 * `nsamples` or `time` (only one of them) 
    - `nsamples` Number of samples to be read. 0 usually means continous reading
    - `time` sampling time in seconds
 * `avg` Number of samples that should be read and averaged for each output.
 * `trigger` An integer specifying the trigger type 0 - internal trigger, other values depend on the specific device.
"""
function daqconfig end

"""
`daqconfigdev(dev; kw...)`

Device configuration. 

Does the samething as [`daqconfig`](@ref) but uses the devices terminology and exact
parameters.
"""
function daqconfigdev end

"""
`daqzero(dev)`

Perform a zero calibration of the DAQ device. The exact nature of this zero calibration.
"""
function daqzero end

"""
`samplesread(dev)`

Return the number of samples read since the beginning of data aquisition.
"""
function samplesread end

"""
`isreading(dev)`

Returns `true` if data acquisition is ongoing, `false` otherwise.
"""
function isreading end

"""
`issamplesavailable(dev)`

Are samples available for reading?
"""
function issamplesavailable end

"""
`numchannels(dev)`

Number of channels available or configured in the DAQ device.
"""
function numchannels end 

"""
`daqchannels(dev)`

Returns the DAQ channels available or configured in the DAQ device.
"""
function daqchannels end


"""
`daqpeek(dev, atend=true)`

Returns data without messing data acquisition or data buffer.
Useful to view data while acquisition is going on.

"""
function daqpeek end


"""
`daqunits(dev, params...)`

Specify data acquisition units. The specific format of the parameters
will depend on device implementation.
"""
function daqunits end
