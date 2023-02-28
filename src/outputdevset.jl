export OutputDevSet

mutable struct OutputDevSet{ODev} <: AbstractOutputDev
    devname::String
    odev::ODev
    devmap::OrderedDict{String,Int}
end

devname(dev::OutputDevSet) = dev.devname
devtype(dev::OutputDevSet) = "OutputDevSet"

"""
`OutputDevSet(devname, odevs)`

Creates a meta device made up of other devices.
In most experiments, more than one device is acted upon.
Consider, as an example, a wind tunnel test where forces
should be measured for different angles of incidence
and different wind speeds. In this case, you will
have an actuator that controls the orientation of the
turn table and another actuator that controls fan speed.
Wit OutputDevSet, both actuators make up a single actuator.

## Examples

```julia-repl
julia> dev1 = TestOutputDev("fan", ["RPM"]);

julia> dev2 = TestOutputDev("turntable", ["Angle"]);

julia> dev = OutputDevSet("wind_tunnel", (dev1, dev2));

julia> axesnames(dev1)
1-element Vector{String}:
 "RPM"

julia> axesnames(dev2)
1-element Vector{String}:
 "Angle"

julia> axesnames(dev)
2-element Vector{String}:
 "RPM"
 "Angle"

julia> numaxes(dev)
2

julia> moveto!(1,dev, [300, 45]) # Set fan speed to 300 RPM and turn the table to 45°

julia> devposition(dev1)
1-element Vector{Float64}:
 300.0

julia> devposition(dev2)
1-element Vector{Float64}:
 45.0

julia> devposition(dev)
2-element Vector{Float64}:
 300.0
  45.0
```
"""
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
function moveto!(k, odevs::OutputDevSet, x)
    
    naxes = 0
    
    for dev in odevs.odev
        nx = numaxes(dev)
        moveto!(k, dev, x[naxes+1:naxes+nx])
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

