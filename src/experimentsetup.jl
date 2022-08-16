
# Setup experimental points

abstract type AbstractExperimentSetup end


mutable struct ExperimentSetup{Pts<:AbstractDaqPoints,ODev<:AbstractOutputDev} <: AbstractExperimentSetup
    "Index of last point measured"
    lastpoint::Int
    "Coordinates of points to be measured"
    points::Pts
    "Output devices to set points"
    odev::ODev
    "Mapping from parameters to axes names"
    axmap::OrderedDict{String,String}
    "Mapping from axes names to parameters"
    parmap::OrderedDict{String,String}
end


function ExperimentSetup(pts::AbstractDaqPoints, odev::AbstractOutputDev)
    params = parameters(pts)
    axes = axesnames(odev)

    if length(params) != length(axes)
        error("Number of parameters is different from number of axes!")
    end

    for (i,p) in enumerate(params)
        a = axes[i]
        if p != a
            error("Parameter $p is different from axis $a! The axes and parameters should be the same and in the same order. A map might help!")
        end
    end
    axmap = OrderedDict{String,String}()
    parmap = OrderedDict{String,String}()
    for p in params
        axmap[p] = p
        parmap[p] = p
    end
    ExperimentSetup(0, pts, odev, axmap, parmap)
end

function ExperimentSetup(pts::AbstractDaqPoints, odev::AbstractOutputDev,
                         axmap::OrderedDict{String,String})
    params = parameters(pts)
    axes = axesnames(odev)
    
    # Check if axes and params are compatible with axmap
    for (p,a) in axmap
        if p ∉ params
            error("Parameter $p not in parameter list!")
        end
        if a ∉ axes
            error("Axis $a not in axes list!")
        end
    end

    # Setup the parameter map
    parmap = OrderedDict{String,String}()
    for (p,a) in axmap
        parmap[a] = p
    end
    
    return ExperimentSetup(0, pts, odev, axmap, parmap)
end


numpoints(expdevs::ExperimentSetup) = numpoints(expdevs.points)
parameters(expdevs::ExperimentSetup) = parameters(expdevs.points)
axesnames(expdevs::ExperimentSetup) = axesnames(expdevs.odev)
"""
`finishedpoints(pts)`

Check if the experiment is done! For `ExperimentPoints`, we should just check
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
    p = daqpoint(pts, lp+1) # Get the coordinates of last point
    a = pts.transf(p)  # Transform to axes
    moveto!(pts.odev, a)
    incpoint!(pts.points)
    return true # We moved, so we have not finished

    
end


    
