

mutable struct OutputDevSet{ODev} <: AbstractOutputDev
    devname::String
    odev::ODev
    devmap::OrderedDict{String,Int}
end

devname(dev::OutputDevSet) = dev.devname
devtype(dev::OutputDevSet) = "OutputDevSet"


function OutputDevSet(dname, odevs::ODev) where {ODev}
    devmap = OrderedDict{String,Int}
    
    for (i,dev) in enumerate(odevs)
        devmap[devname(dev)] = i
    end
    
    OutputDevSet(dname, odev, devname)
end

OutputDevSet(dname, odevs...) where {ODev} = OutputDevSet(dname, odevs)

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


function movenext!(pts::ExperimentSetup{Pts,ODev}) where {Pts<:AbstractDaqPoints,
                                                          ODev<:OutputDevSet}
    # Have we finished the measurements?
    finishedpoints(pts) && return false  # It is over.

    lp = lastpoint(pts) # Index of last point tested
    x_next = daqpoint(pts.points, lp+1) # Coordinates to the next point

    #=
    When the output device is an `OutputDevSet`, each device should move independently.
    Often this movement takes some time so it should be done only if necessary.
    If the next point doesn't move some of the devices, then it shouldn't move.
    An extreme situation happens when a device is manual, then moving every device
    would imply waiting for manual input on every point, defeating any automation
    on all other devices.

    The idea is that devices that are more "difficult" to move (take longer, require
    manual intervential, cost more), should be moved least of all. So the points with
    coordinates corresponding to these "more expensive" devices should be programmed
    to move less often.
    
    =#
    if lp == 0    # If it is the first point, move everything to it.
        for  k in eachindex(pts.odev)
            ax = axesnames(pts.odev[k]) # Get the name of the axes
            a_next = [x_next[pts.parmap[aa]] for aa in ax]
            moveto!(pts.odev[k], a_next)
        end
    else # It is not the first point
        x_last = daqpoint(pts, lp)
        for k in eachindex(pts.odev)
            ax = axesnames(pts.odev[k]) # Get the name of the axes
            a_next = [x_next[pts.parmap[aa]] for aa in ax]
            a_last = [x_last[pts.parmap[aa]] for aa in ax]

            # We only need to move the device *if* the points have changed!
            if a_next != a_last
                moveto!(pts.odev[k], a_next)
            end
        end
    end
    incpoint!(pts)
end

