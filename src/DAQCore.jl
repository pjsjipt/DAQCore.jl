module DAQCore


import DataStructures: OrderedDict


export AbstractDevice, AbstractInputDev, AbstractOutputDev, AbstractPressureScanner
export AbstractDaqConfig, AbstractDaqTask
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
include("measdata.jl")
include("config.jl")
include("channels.jl")
include("deviceset.jl")
include("daqtask.jl")
include("points.jl")
include("outputdev.jl")
include("experimentsetup.jl")
include("outputdevset.jl")
include("testdaqdev.jl")

end
