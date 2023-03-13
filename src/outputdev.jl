# Generic interface for output devices

export OutputDev, numaxes, axesnames, moveto!, devposition, stopoutputdev
export waituntildone

"""
`OutputDev(devname, devtype, axes, config)`

Generic interface for output devices. Mostly used for IO of devices
that have no specific methods implemented.
"""
struct OutputDev <: AbstractOutputDev
    devname::String
    devtype::String
    axes::Vector{String}
    config::DaqConfig
end

devname(dev::OutputDev) = dev.devname
devtype(dev::OutputDev) = dev.devtype

"""
`numaxes(dev)`

Return the number of degrees of freedom of the actuator.
"""
function numaxes end


"""
`axesnames(dev)`

Return the names of each individual axis on an output device.
"""
function axesnames end

"""
`moveto!(move, x)`

Move to an arbitrary point. The point is specified by vector `x`. 

"""
function moveto! end

"""
`devposition(dev)`

Returns a vector with the present position of the output device.
"""
function devposition end

"""
`stopoutputdev(dev)`

Stop all motion of the robot. 
"""
function stopoutputdev end


"""
`waituntildone(dev)`

Only return when all output is done.
"""
function waituntildone end



numaxes(dev::OutputDev) = length(dev.axes)
axesnames(dev::OutputDev) = dev.axes


