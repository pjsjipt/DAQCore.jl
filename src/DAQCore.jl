module DAQCore


import DataStructures: OrderedDict


export AbstractDevice, AbstractInputDev, AbstractOutputDev, AbstractPressureScanner
export AbstractDaqConfig, AbstractDaqTask, AbstractExperiment
export AbstractExperimentSetup, AbstractDaqFilter

export devname, devtype
"Abstract type to handle any kind of device"
abstract type AbstractDevice end

"Abstract type to handle data acquisition (input) devices"
abstract type AbstractInputDev <: AbstractDevice end

"Abstract type to handle actuators, that is, output devices"
abstract type AbstractOutputDev <: AbstractDevice end

"Base type for device configuration"
abstract type AbstractDaqConfig end

"Base type for data acquisition task"
abstract type AbstractDaqTask end

"Abstract type to handle pressure scanners"
abstract type AbstractPressureScanner <: AbstractInputDev end

"Abstract type to handle generic, complete experiments"
abstract type AbstractExperiment end

"Abstract type to deal with experimental setup (input/output devices, points)"
abstract type AbstractExperimentSetup end
"Abstract channel definintion type"
abstract type AbstractDaqChannels end
"Abstract sampling times and rates type"
abstract type AbstractDaqSampling end
"Abstract experimental points definition"
abstract type AbstractDaqPoints end

"Abstract type for representing filters and data transformations"
abstract type AbstractDaqFilter end


"""
`devname(dev::AbstractDevice)`

The device name is a string that is used to refer to a specific device.

This string is used when saving data and post processing.
"""
function devname end

devname(dev::AbstractDevice) = dev.devname

"Returns the type of device"
function devtype end
devtype(dev::AbstractDevice) = string(typeof(dev))



include("utils.jl")
include("daq.jl")
include("circbuffer.jl")
include("config.jl")
include("channels.jl")
include("sampling.jl")
include("measdata.jl")
include("deviceset.jl")
include("daqtask.jl")
include("points.jl")
include("outputdev.jl")
include("outputdevset.jl")
include("plan.jl")
include("experimentsetup.jl")
include("testdaqdev.jl")
include("testoutputdev.jl")


"Empty generic function for filter application"
function daqfilter end

"Empty generic function for filter application"
function daqfilter! end

devtype(filt::AbstractDaqFilter) = "Filter"

(filt::AbstractDaqFilter)(x::AbstractMeasData) = daqfilter(filt, x)
(filt::AbstractDaqFilter)(x::AbstractMeasData, y) = daqfilter!(filt, x, y)

end
