# Data structures to help define experimental points

export AbstractDaqPoints, DaqPoints, CartesianDaqPoints, DaqPointsProduct
export parameters, numpoints, numparams, daqpoint, daqpoints
abstract type AbstractDaqPoints end

mutable struct DaqPoints <: AbstractDaqPoints
    "Name of parameters that characterize the point"
    params::Vector{String}
    "Set of positions in the test matrix"
    pts::Matrix{Float64}
end


"""
`DaqPoints(params, pts)`
`DaqPoints(;kw...)`

Defines a sequence of predefined points that characterize an experiment.

The points are defined by a `Matrix{Float64}` where each column corresponds to a 
parameter (degree of freedom) of the system. Each row characterizes a specific point.

## Arguments

 * `params` Vector/tuple containing the names of the parameters that define the position. It will be converted to a string.
 * `pts` Matrix that contains the points. Each column corresponds to a variable and each row to a single point.
 * `kw...` Keyword arguments where the names of the keywords correspond to the variables and the values to the possible positions. The length of each keyword argument should be the same or 1. If its 1, it will be repeated.

"""
function DaqPoints(params, pts::AbstractMatrix{Float64})
    
    npars = size(pts, 2)
    nvals = size(pts, 1)
    
    length(params) != npars && thrown(ArgumentError("Wrong number of variable names!"))
    
    testpts = zeros(Float64, nvals, npars)
    for i in 1:npars
        for k in 1:nvals
            testpts[k,i] = pts[k,i]
        end
    end
    params1 = [string(v) for v in params]
    return DaqPoints(params1, testpts)

end

function DaqPoints(;kw...) 

    params = [string(k) for k in keys(kw)]
    nvals = maximum(length(v) for (k,v) in kw)

    testpts = zeros(Float64, nvals, length(keys(kw)))

    ivar = 1
    for (k,v) in kw
        if length(v) == 1
            for i in 1:nvals
                testpts[i,ivar] = Float64(v[1])
            end
        elseif length(v) != nvals
            throw(ArgumentError("All arguments lengths should be the same or 1!"))
        else
            for i in 1:nvals
                testpts[i,ivar] = Float64(v[i])
            end
        end
        ivar += 1
    end
    return DaqPoints(params, testpts)
    
end




"""
`parameters(pts)`


Returns the names of the parameters.
"""
parameters(pts::AbstractDaqPoints) = pts.params

"Number of parameters in an `DaqPoints"
numparams(M::DaqPoints) = length(M.params)

"""
`numpoints(pts)`

Returns the number of points in a set of experiment points.
"""
numpoints(pts::DaqPoints) = size(pts.pts,1)


daqpoint(pts::DaqPoints, i) = pts.pts[i, :]
daqpoints(pts::DaqPoints) = pts.pts

mutable struct CartesianDaqPoints <: AbstractDaqPoints
    params::Vector{String}
    axes::Vector{Vector{Float64}}
    pts::Matrix{Float64}
end

"""
`cartesianprod(x::Vector{Vector{T}})`
`cartesianprod(x...)`

Performs a cartesian product between vectors

"""
function cartesianprod(x::Vector{Vector{T}}) where {T}
    npars = length(x)
    n = length.(x)
    ntot = prod(n)
    pts = zeros(T, ntot, npars)
    strd = zeros(Int, npars)
    strd[1] = 1
    for i in 2:npars
        strd[i] = strd[i-1] * n[i-1]
    end

    for i in 1:npars # Each variable corresponds to a column
        xi = x[i] # Select the variable
        Ni = n[i]
        Si = strd[i]
        cnt = 1
        Nr = ntot ÷ (Ni*Si)
        for k in 1:Nr
            for j in 1:Ni
                for l in 1:Si
                    pts[cnt,i] = xi[j]
                    cnt += 1
                end
            end
        end

    end

    return pts
end
cartesianprod(x1...) = cartesianprod([collect(y) for y in x1])

"""
`CartesianDaqPoints(;kw...)`

Creates a test matrix that is a cartesian product  of independent parameters.
This is useful if the test should be executed on a regular grid, x, y for example.
In this grid, the length of x is n₁ and the length of y is n₂. The number of points
in the test is therefore nx⋅ny.

The first parameters run faster:

```julia
pts = CartesianMatrix(x=1:3, y=5:5:25)
```

In this case, 
The points of the test matrix are

| x  | y  |
|----|----|
| x₁ | y₁ |
| x₂ | y₁ |
| ⋮  | ⋮  |
| xₙ₁| y₁ |
| x₁ | y₂ |
| x₂ | y₂ |
| ⋮  | ⋮  |
| xₙ₁| yₙ₂|


"""
function CartesianDaqPoints(;kw...)
    params = string.(collect(keys(kw)))
    axes = Vector{Float64}[]
    npars = length(params)
    for (k, v) in kw
        push!(axes, [Float64(x) for x in v])
    end
    pts = cartesianprod(axes)
    return CartesianDaqPoints(params, axes, pts)
end

numpoints(pts::CartesianDaqPoints) = size(pts.pts, 1)
numparams(pts::CartesianDaqPoints) = length(pts.params)
daqpoint(pts::CartesianDaqPoints, i) = pts.pts[i,:]
daqpoints(pts::CartesianDaqPoints) = pts.pts


    
mutable struct DaqPointsProduct{PtsLst} <: AbstractDaqPoints
    "List of experimental points objects"
    points::PtsLst
    "Matrix with points index in each actuator"
    ptsidx::Matrix{Int}
    DaqPointsProduct(points::PtsLst, ptsidx::Matrix{Int}) where {PtsLst} =
        new{PtsLst}(points, ptsidx)
end



"""
`DaqPointsProduct(points::PtsLst)`


Cartesian product between different AbstractDaqPoints objects.

Imagine an experiment where several actuators are used. As an example, in a 
wind tunnel this could be a cartesian robot with 3 axes, the turn table and 
fan speed. During the experiment, all actuators will be used and each 
experimental point corresponds to a a given configuration of the actuators.

The `DaqPointsProduct` combines the the experimental points of each 
actuator into a single 'meta-'point. 

The arguement `points` is a tuple or vector of `AbstractExeperimentMatrix`.

The order of motion is: first points first. 
"""
function DaqPointsProduct(points::PtsLst) where {PtsLst}
    
    n = numpoints.(points)
    nmats = length(points)
    ii = Vector{Int}[]

    for i in 1:nmats
        push!(ii, collect(1:n[i]))
    end
    ptsidx = cartesianprod(ii)
    return DaqPointsProduct(points, ptsidx)
end
function DaqPointsProduct(pts...)
    return DaqPointsProduct(pts)
end

    
"Number of points in `DaqPointsProduct`"
numpoints(pts::DaqPointsProduct) = size(pts.ptsidx,1)
"Number of parameters in `DaqPointsProduct`"
numparams(pts::DaqPointsProduct) = sum(numparams.(pts.points))
"Names of matrix parameters `DaqPointsProduct`"
parameters(pts::DaqPointsProduct) = vcat([parameters(p) for p in pts.points]...)


"""
`daqpoint(pts::DaqPointsProduct, i)`

Returns the i-th test point (coordinates of the points).
"""
function daqpoint(pts::DaqPointsProduct, i)
    x = Float64[]

    for (k,p) in enumerate(pts.points)
        ki = pts.ptsidx[i,k]
        append!(x, daqpoint(p, ki))
    end
    return x
    
end

"""
`daqpoints(pts::DaqPointsProduct)`

Returns a matrix with the coordinates of every experiment point.
Each row corresponds to an experiment point and each column to an 
experiment parameter (axis).
"""
function daqpoints(pts::DaqPointsProduct)
    npts = numpoints(pts)

    nparams = numparams(pts)
    points = zeros(npts, nparams)

    for i in 1:npts
        points[i,:] .= daqpoint(pts, i)
    end
    return points
end

"""
`m1*m2`

Cartesian product between two `TestMatrices`. Used to combine different test matrices into 
a single one. 

The cartesian product is built so that the object on the right hand side of the 
multiplication runs faster. 

## Examples

```julia-repl
julia> M1 = DaqPoints(;x=1:3, y=100:100:300)
DaqPoints(0, ["x", "y"], [1.0 100.0; 2.0 200.0; 3.0 300.0])

julia> M2 = DaqPoints(z=1:4)
DaqPoints(0, ["z"], [1.0; 2.0; 3.0; 4.0;;])

julia> M = M1*M2
DaqPoints(0, ["x", "y", "z"], [1.0 100.0 1.0; 1.0 100.0 2.0; … ; 3.0 300.0 3.0; 3.0 300.0 4.0])

julia> numparams(M1)
2

julia> numparams(M2)
1

julia> numparams(M)
3
```
"""
*(m1::AbstractDaqPoints, m2::AbstractDaqPoints) =
    DaqPointsProduct(m1, m2)
    




