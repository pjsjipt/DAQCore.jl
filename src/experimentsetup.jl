
# Setup experimental points

export ExperimentSetup, lastpoint, incpoint!, setpoint!, movenext!
export finishedpoints
abstract type AbstractExperimentSetup end


mutable struct ExperimentSetup{IDev<:AbstractInputDev,Pts<:AbstractDaqPoints,ODev<:AbstractOutputDev} <: AbstractExperimentSetup
    "Index of last point measured"
    lastpoint::Int
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
    return ExperimentSetup(0, idev, pts, odev, axmap1, parmap, idx)
end


numpoints(expdevs::ExperimentSetup) = numpoints(expdevs.points)
parameters(expdevs::ExperimentSetup) = collect(keys(expdevs.parmap))
axesnames(expdevs::ExperimentSetup) = collect(keys(expdevs.axmap))
numaxes(expdevs::ExperimentSetup) = length(expdevs.axmap)
numparams(expdevs::ExperimentSetup) = length(expdevs.axmap)


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
    moveto!(pts.odev, a)
    incpoint!(pts.points)
    return true # We moved, so we have not finished

    
end

    
daqpoints(pts::ExperimentSetup) = daqpoints(pts.points)
daqpoint(pts::ExperimentSetup, i) = daqpoint(pts.points, i)
