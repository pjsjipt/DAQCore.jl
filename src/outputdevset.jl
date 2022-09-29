export OutputDevSet

mutable struct OutputDevSet{ODev} <: AbstractOutputDev
    devname::String
    odev::ODev
    devmap::OrderedDict{String,Int}
end

devname(dev::OutputDevSet) = dev.devname
devtype(dev::OutputDevSet) = "OutputDevSet"


function OutputDevSet(dname, odevs::ODev) where {ODev}
    devmap = OrderedDict{String,Int}()
    
    for (i,dev) in enumerate(odevs)
        devmap[devname(dev)] = i
    end
    
    OutputDevSet(dname, odevs, devmap)
end

#OutputDevSet(dname, odevs...) where {ODev} = OutputDevSet(dname, odevs)

import Base.getindex
getindex(dev::OutputDevSet, i) = dev.odev[i]
getindex(dev::OutputDevSet, d::AbstractString) = dev.odev[dev.devmap[d]]




    
"Number of axes (degrees of freedom) of the actuator set"
numaxes(dev::OutputDevSet) = sum(numaxes(d) for d in dev.odev)


"Return the axes names of the `ActuatorSet`"
function axesnames(devices::OutputDevSet)

    nn = String[]

    for dev in devices.odev
        axes = axesnames(dev)
        append!(nn, axes)
    end
    return nn
end

"Get the output devices s to `move` to a point given by the components of x"
function moveto!(odevs::OutputDevSet, x)
    
    naxes = 0
    
    for dev in odevs.odev
        nx = numaxes(dev)
        moveto!(dev, x[naxes+1:naxes+nx])
        naxes += nx
    end
    return
    
end

function devposition(odev::OutputDevSet)

    p = Float64[]
    for dev in odev.odev
        append!(p, devposition(dev))
    end
    return p
    
end

