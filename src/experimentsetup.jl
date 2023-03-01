
# Setup experimental points

export ExperimentSetup, lastpoint, incpoint!, setpoint!, movenext!
export finishedpoints, inputdevice, outputdevice

"""
`ExperimentSetup(idev, pts, odev)`

Creates a structure that handles experiment setup.
Experiment setup in this context is the set of input devices,
output devices and points where the output devices should be
positioned to measure the input devices.

The output device (`odev`) is used to set the configuration corresponding to each
point (`points`) where the input device (`idev`) will measure the data.

This is done sequentially from the first point until the test ends.

The point that was done is specified by the field `lastpoint`. Usually when an
experiment begins, there was no previous point and `lastpoint=0`. Once the
experiemnt begins, field `started` is set to `true`. The output device (`odev`)
'moves' the system to the first point using method [`movenext!`](@ref).
While there are points to be measured, the method [`movenext!`](@ref) returns `true`.
Once the last point has been measured, [`movenext!`](@ref) returns `false` and
the experiment is considered over.

To 'move' the system to a new point (defined in field `points`), [`movenext!`](@ref)
acts on the output device `odev`. Each parameter in `points` corresponds to an
axis in `odev`. If `points` and `odev` were created with different names, a map can
be specified.

`ExperimentSetup` does not do any coordinate change. This should be defined outside,
preferably by creating a new output device that handles the transformation.

If the output device is a [`OutputDevSet`](@ref) and the points
[`DaqPointsProduct`](@ref), the method [`movenext`](@ref) will move each
output device independently and will check if the points associated with
the axes of each individual output device that makes up the `OutputDevSet`
actually changed.

## Examples

```julia-repl
ulia> idev = TestDaq("Device1"); daqaddinput(idev, ["E1", "E2"]);

julia> odev = TestOutputDev("fan", ["RPM"]);

julia> pts = DaqPoints(vel=200:50:300);

julia> setup = ExperimentSetup(idev, pts, odev, Dict("RPM"=>"vel"));

julia> while movenext!(setup)
           println(daqpoint(setup.points, lastpoint(setup)))
       end
[200.0]
[250.0]
[300.0]
```
"""
mutable struct ExperimentSetup{IDev<:AbstractInputDev,Pts<:AbstractDaqPoints,ODev<:AbstractOutputDev} <: AbstractExperimentSetup
    "Index of last point measured"
    lastpoint::Int
    "Has the experiment started?"
    started::Bool
    "Data Input Devices"
    idev::IDev
    "Coordinates of points to be measured"
    points::Pts
    "Output devices to set points"
    odev::ODev
    "Mapping from parameters to axes names"
    axmap::OrderedDict{String,String}
    "Mapping from axes names to parameters"
    parmap::OrderedDict{String,String}
    "Index of each parameter corresponding to the ith axis"
    idx::Vector{Int}
end




function setup_ap_map(axes, params, axmap1)
    p1 = unique(params)
    a1 = unique(axes)

    length(p1) != length(params) &&  error("Repeated parameters. Don't know how to handle this!")
    length(a1) != length(axes) &&  error("Repeated axes. Don't know how to handle this!")

    length(params) != length(axes) && error("The number of axes should be the same as the number of parameters!")

    axmap = OrderedDict{String,String}()
    pamap = OrderedDict{String,String}()

    
    # Every axe should be associated to a parameter.
    # We map axes to parameters. The order is given by axes.
    # We do this because this determines the order of acting
    # on the output devices.
    for a in axes
        if a ∉ keys(axmap1)
            error("Axis $a not mapped to a parameter")
        end
        p = axmap1[a]
        if p ∉ values(axmap1)
            error("Parameter $p not mapped to an axis!")
        end
        
        p = axmap1[a]
        axmap[a] = p
        pamap[p] = a
    end
    param_idx = Dict{String,Int}()
    for (i,p) in enumerate(params)
        param_idx[p] = i
    end

    idx = zeros(Int,length(params))
    for (i,a) in enumerate(axes)
        p = axmap[a]
        k = param_idx[p]
        idx[i] = k
    end
    
    return axmap, pamap, idx
        
end

function setup_ap_map(axes, params)
    np = length(params)
    np != length(axes) && error("Incompatible length between parameters and axes!")

    axmap = OrderedDict{String,String}()
    for (a,p) in zip(axes, params)
        axmap[a] = p
    end

    return setup_ap_map(axes, params, axmap)
end



function ExperimentSetup(idev::AbstractInputDev, pts::AbstractDaqPoints,
                         odev::AbstractOutputDev, axmap::AbstractDict{String,String})

    
    params = parameters(pts)
    axes = axesnames(odev)
    
    # Check compatibility and setup axes map
    axmap1, parmap, idx = setup_ap_map(axes, params, axmap)
    return ExperimentSetup(0, false, idev, pts, odev, axmap1, parmap, idx)
end


function ExperimentSetup(idev::AbstractInputDev, pts::AbstractDaqPoints,
                         odev::AbstractOutputDev)

    axmap = OrderedDict{String,String}()
    for p in parameters(pts)
        axmap[p] = p
    end
    return ExperimentSetup(idev, pts, odev, axmap)
end



"""
`finishedpoints(pts)`

Check if the experiment is done! For `ExperimentSetup`, we should just check
whether the index of the lastpoint corresponds to the number of points.

It is possible, in some applications, to have a dynamic behavior so that a priori
there is no set number of points. In cases like this, a new method should be created
that check if the problem is done.

"""
finishedpoints(pts::ExperimentSetup) = pts.lastpoint == numpoints(pts.points)

"""
`lastpoint(pts)`

Return the index of the last point tested. Point `0` means that no points were tested.
"""
lastpoint(pts::AbstractExperimentSetup) = pts.lastpoint

"""
`incpoint(pts)`

Increment point counter.
"""
incpoint!(pts::AbstractExperimentSetup) = pts.lastpoint += 1

"""
`setpoint!(pts, i)`

Set point counter so that the next point tested is the `i-th` point.
Remember that the first point is 1 and therefore to restart things,
the last point should be 0. 

"""
setpoint!(pts::AbstractExperimentSetup, i) = pts.lastpoint = i-1  # Lastpoint

"""
`movenext!(pts)`

Move to the next point. Basic interface to carry out an experiment.

"""
function movenext!(pts::ExperimentSetup)
    finishedpoints(pts) && return false  # It is over.
    
    lp = lastpoint(pts)
    p = daqpoint(pts.points, lp+1) # Get the coordinates of last point
    pax = p[pts.idx]
    moveto!(lp+1, pts.odev, pax)
    incpoint!(pts)

    if (lp+1) > numpoints(pts) # Last point
        pts.started = false
        return false
    else
        return true # We moved, so we have not finished
    end
    

    
end




daqpoints(pts::ExperimentSetup) = daqpoints(pts.points)
daqpoint(pts::ExperimentSetup, i) = daqpoint(pts.points, i)
parameters(pts::ExperimentSetup) = parameters(pts.points)
numparams(pts::ExperimentSetup) = numparams(pts.points)
numpoints(pts::ExperimentSetup) = numpoints(pts.points)

axesnames(pts::ExperimentSetup) = axesnames(pts.odev)
numaxes(pts::ExperimentSetup) = numaxes(pts.odev)

"Return the input device of the `ExperimentSetup`"
inputdevice(pts::ExperimentSetup) = pts.idev
"Return the output device of the `ExperimentSetup`"
outputdevice(pts::ExperimentSetup) = pts.odev


"""
`movenext!(setup)`

Move to the next point in the experiment when dealing with [`OutputDevSet`](@ref) meta
device sets. If the experiment point is not the first one, it will act on the output
devices if the next point changed it.

It would seem intuitive to just call [`devposition`](@ref) and check if we are moving
but some devices provide approximate values that might not correspond to the
exact position specified by points. 

"""
function movenext!(pts::ExperimentSetup{IDev,Pts,ODev}) where {IDev<:AbstractInputDev,
                                                               Pts<:AbstractDaqPoints,
                                                               ODev<:OutputDevSet}
    # Have we finished the measurements?
    finishedpoints(pts) && return false  # It is over.

    lp = lastpoint(pts) # Index of last point tested
    x_next = daqpoint(pts.points, lp+1) # Coordinates to the next point
    has_started = pts.started # Have we started moving yet?
    
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
    if !has_started    # If it is the first point, move everything to it.
        for  k in eachindex(pts.odev)
            ax = axesnames(pts.odev[k]) # Get the name of the axes
            a_next = [x_next[pts.parmap[aa]] for aa in ax]
            moveto!(k, pts.odev[k], a_next)
        end
        pts.started = true
    else # It is not the first point
        x_last = daqpoint(pts, lp)
        for k in eachindex(pts.odev)
            ax = axesnames(pts.odev[k]) # Get the name of the axes
            a_next = [x_next[pts.parmap[aa]] for aa in ax]
            a_last = [x_last[pts.parmap[aa]] for aa in ax]

            # We only need to move the device *if* the points have changed!
            if a_next != a_last
                moveto!(k, pts.odev[k], a_next)
            end
        end
    end
    incpoint!(pts)

    if (lp+1) == numpoints(pts) # Last point
        pts.started = false
        return false
    else
        return true # We moved, so we have not finished
    end
    
    
end

