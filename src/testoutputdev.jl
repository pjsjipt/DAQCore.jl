export TestOutputDev

mutable struct TestOutputDev <: AbstractOutputDev
    devname::String
    n::Int
    x::Vector{Float64}
    xr::Vector{Float64}
    axes::Vector{String}
    axidx::Dict{String,Int}
    Δt::Float64
end


"""
`TestOutputDev(devname, axes=["x", "y", "z"]; dt=0.0)`

Creates a cartesian robot with several axes. It tries to emulate the interface
used by the wind tunnel's cartesian robot (see the `RoboSimples` package at
<https://github.com/pjsjipt/RoboSimples.jl>).
"""
function TestOutputDev(devname, axes=["x", "y", "z"]; dt=0.0)
    n = length(axes)
    axidx = Dict{String,Int}()
    axes = axes[1:n]
    for (i, ax) in enumerate(axes)
        axidx[ax] = i
    end
    
    TestOutputDev(devname, n, zeros(n), zeros(n), axes, axidx, dt)
end

numaxes(dev::TestOutputDev) = dev.n
axesnames(dev::TestOutputDev) = dev.axes

function move(dev::TestOutputDev, ax::Integer, mm; r=false)
    if r
        dev.x[ax] += mm
    else
        dev.x[ax] = mm
    end
    #sleep(dev.Δt)
    println("Position: $ax -> $(dev.axes[ax]) = $(dev.x[ax])")
end

move(dev::TestOutputDev, ax, mm; r=false) =
    move(dev, dev.axidx[string(ax)], mm; r=r)


function move(dev::TestOutputDev, axes::AbstractVector,
                                x::AbstractVector; r=false)
    ndof = length(axes)

    for i in 1:ndof
        move(dev, axes[i], x[i]; r=r)
    end
    return
end

moveto!(dev::TestOutputDev, x::AbstractVector) = move(dev, dev.axes, x, r=false)

moveX(dev::TestOutputDev, mm) = move(dev, mm, dev.axidx["x"]; r=false)
moveY(dev::TestOutputDev, mm) = move(dev, mm, dev.axidx["y"]; r=false)
moveZ(dev::TestOutputDev, mm) = move(dev, mm, dev.axidx["z"]; r=false)

rmoveX(dev::TestOutputDev, mm) = move(dev, mm, dev.axidx["x"]; r=true)
rmoveY(dev::TestOutputDev, mm) = move(dev, mm, dev.axidx["y"]; r=true)
rmoveZ(dev::TestOutputDev, mm) = move(dev, mm, dev.axidx["z"]; r=true)

devposition(dev::TestOutputDev, ax) = dev.x[dev.axidx[string(ax)]]
devposition(dev::TestOutputDev, ax::Integer) = dev.x[ax]

devposition(dev::TestOutputDev, axes::AbstractVector) = dev.x[axes]

function devposition(dev::TestOutputDev)
    pos = OrderedDict{String,Float64}()

    for i in 1:numaxes(dev)
        pos[dev.axes[i]] = dev.x[i]
    end
    return pos
end

positionX(dev::TestOutputDev) = devposition(dev, "x")
positionY(dev::TestOutputDev) = devposition(dev, "y")
positionZ(dev::TestOutputDev) = devposition(dev, "z")

setreference(dev::TestOutputDev, ax::Integer, mm=0) = dev.x[ax] = mm
setreference(dev::TestOutputDev, ax, mm=0) = dev.x[dev.axidx[string(ax)]] = mm
setreference(dev::TestOutputDev) = dev.x .= 0.0

function setreference(dev::TestOutputDev, ax::AbstractVector, mm=0)
    nax = length(ax)
    if length(mm) == 1
        mm = fill(mm[1], nax)
    end

    for i in 1:nax
        setreference(dev, ax[i], mm[i])
    end
    
end

setreferenceX(dev::TestOutputDev, mm=0) = dev.x[dev.axidx["x"]] = mm
setreferenceY(dev::TestOutputDev, mm=0) = dev.x[dev.axidx["y"]] = mm
setreferenceZ(dev::TestOutputDev, mm=0) = dev.x[dev.axidx["z"]] = mm


