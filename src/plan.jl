# Experiment Plan
#
export AbstractDaqPlan, DaqPlan, startplan!
export lastpoint, incpoint!, setpoint!, movenext!, finishedpoints
export outputdevice


abstract type AbstractDaqPlan end




mutable struct DaqPlan{ODev<:AbstractOutputDev,
                       Pts<:AbstractDaqPoints} <: AbstractDaqPlan
    devname::String
    devtype::String
    lastpoint::Int
    started::Bool
    "Output device that configure a position"
    dev::ODev
    "Experimental points that should be configured"
    points::Pts
    "Axes of output devices"
    axes::Vector{String}
    "Axes values for each point"
    avals::Matrix{Float64}
end


function DaqPlan(devname::AbstractString, devtype::AbstractString,
                 dev::AbstractOutputDev, points::AbstractDaqPoints)
    

    axes = axesnames(dev)
    np = numpoints(points)
    pts = daqpoints(points)
    params = parameters(points)

    # In this case we will assume that the axes names is the same as
    # parameters.
    # First we check if every axis is in the parameters
    idx = Int[]
    for a in axes
        found = false
        for (i,p) in enumerate(params)
            if p==a
                push!(idx, i)
                found = true
                break
            end
        end
        if !found
            error("Axis $a not a parameter of the points")
        end
    end

    avals = pts[:,idx]
    return DaqPlan(devname, devtype, 0, false, dev, points, axes, avals)
end

DaqPlan(dev::AbstractOutputDev, points::AbstractDaqPoints) =
    DaqPlan(devname(dev), devtype(dev), dev, points)

devname(dev::DaqPlan) = dev.devname
devtype(dev::DaqPlan) = dev.devtype
outputdevice(dev::DaqPlan) = dev.dev

parameters(dev::DaqPlan) = parameters(dev.points)
numparams(dev::DaqPlan) = numparams(dev.points)
numpoints(dev::DaqPlan) = numpoints(dev.points)
daqpoints(dev::DaqPlan) = daqpoints(dev.points)
daqpoint(dev::DaqPlan, i) = daqpoints(dev.points, i)

numaxes(dev::DaqPlan) = length(dev.axes)
axesnames(dev::DaqPlan) = dev.axes
lastpoint(dev::DaqPlan) = dev.lastpoint
incpoint!(dev::DaqPlan) = dev.lastpoint += 1
setpoint!(dev::DaqPlan, i) = dev.lastpoint = i-1

finishedpoints(dev::DaqPlan) = dev.lastpoint == numpoints(dev)


function startplan!(dev::DaqPlan)
    dev.lastpoint = 0
    dev.started = false
end

function moventh!(dev::DaqPlan, i) 
    if i > numpoints(dev)
        return false
    end
    x = dev.avals[i,:]
    moveto!(dev.dev, x)
    dev.started = true
    true
end


function movenext!(dev::DaqPlan)

    
    if finishedpoints(dev)
        return false
    end
    lp = lastpoint(dev)
    x = dev.avals[lp+1,:]
    moveto!(dev.dev, x)
    incpoint!(dev)
    dev.started = true
    return true
end

function movefirst!(dev::DaqPlan)
   
    x = dev.avals[1,:]
    moveto!(dev.dev, x)
    setpoint!(dev, 1)

    dev.started = true
    return true
end

function get_vals(a, axes, vals)

    x = Float64[]
    for a1 in a
        for (ax,val) in zip(axes, vals)
            if a1 == ax
                push!(x, val)
                break
            end
        end
    end
    return x
end

        
function movenext!(dev::DaqPlan{OutputDevSet})

    if finishedpoints(pts)
        return false
    end
    
    lp = lastpoint(dev)
    x_next = dev.xvals[lp+1,:]
    
    if !dev.started # First point, move avery sub-device
        for kdev in dev.dev
            ax = axesnames(kdev)
            aval = get_vals(ax, dev.axes, x_next)
            moveto!(kdev, aval)
        end
        dev.started = true
    else # It is not the last point
        # Move only the devices that need moving
        x_last = dev.xvals[lp,:]
        for kdev in dev.dev
            ax = axesnames(kdev)
            a_next = get_vals(ax, dev.axes, x_next)
            a_last = get_vals(ax, dev.axes, x_last)

            if a_next != a_last
                moveto!(kdev, a_next)
            end
        end
    end
    incpoint!(dev)
end

            
        
        
    

    
    


#=
    "Mapping from parameters to axes names"
    axmap::OrderedDict{String,String}
    "Mapping from axes names to parameters"
    parmap::OrderedDict{String,String}
    "Index of each parameter corresponding to the ith axis"
    idx::Vector{Int}
=#

function setup_ap_map(axes, params)
    np = length(params)
    np != length(axes) && error("Incompatible length between parameters and axes!")

    axmap = OrderedDict{String,String}()
    for (a,p) in zip(axes, params)
        axmap[a] = p
    end

    return setup_ap_map(axes, params, axmap)
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
