
using Dates
export MeasData, measdata, samplingrate, daqunits, daqunit

"Base type for measurement data sets"
abstract type AbstractMeasData end


mutable struct MeasData{T,AT<:AbstractMatrix{T},
                        S<:AbstractDaqSampling,CH} <: AbstractMeasData
    "Device that generated the data"
    devname::String
    "Type of device"
    devtype::String
    "Sampling timing data"
    sampling::S
    "Data acquired"
    data::AT
    "Channel Information"
    chans::CH
    "Units of each channel"
    units::Vector{String}
end


"""
`MeasData(devname, devtype, sampling, data, chans, units)`

Structure to store data acquired from a DAQ device. It also stores metadata related to 
the DAQ device, data acquisition process and daq channels.

When an input device acquires data, this device has a `devname` by which it is referred
to in all of the `DAQCore` ecosystem. It also has a type, sampling information, the data
itself and channel information. The `MeasData` handles all of this.

Most often, the data will be stored as a matrix where each *column* corresponds to a sample.
Of course, any other type of arrangement is possible since this is a parametric field
(image information could be an example of a different type of data). But most methods
assume that the data is stored as a matrix and each sample corresponds to a column. For other
configurations, methods might have to be implemented.

The sampling information refers to the timing of each sample, in most cases it will be
a [`DaqSamplingRate`](@ref) or [`DaqSamplingTimes`](@ref) object but more specific information
can be stored since this is a parametric field.

The information on the channels is stored in the `chans` field.

Data from specific channels can be retrieved using the `getindex` method either specifying the
channel name or channel index.

Most methods related to [`DaqChannels`](@ref) are reimplemented for `MeasData`. The same is true
for sampling information (usually [`DaqSamplingRate`](@ref)  or [`DaqSamplingTimes`](@ref))
## Example

```julia-repl
julia> ch = DaqChannels("E", 4)
DaqChannels{String, String}("test", "TestDevice", "", ["E1", "E2", "E3", "E4"], OrderedCollections.OrderedDict("E1" => 1, "E2" => 2, "E3" => 3, "E4" => 4), "")

julia> s = DaqSamplingRate(1.0, 5, now())
DaqSamplingRate(1.0, 5, DateTime("2022-10-04T10:36:33.722"))

julia> data = randn(4,5);

julia> X = MeasData("Test", "TestDevice", s, data, ch);

julia> X[1]
5-element view(::Matrix{Float64}, 1, :) with eltype Float64:
  1.2410386624221996
 -0.6314641591019056
  1.2806557053182634
  0.23158415744317515
 -0.10486298127332715

julia> X["E1"]
5-element view(::Matrix{Float64}, 1, :) with eltype Float64:
  1.2410386624221996
 -0.6314641591019056
  1.2806557053182634
  0.23158415744317515
 -0.10486298127332715

julia> numsamples(X)
5

julia> samplingrate(X)
1.0

julia> X[]
4×5 Matrix{Float64}:
  1.24104   -0.631464    1.28066    0.231584  -0.104863
  0.166224  -0.671223   -1.35862   -0.342828   0.215685
 -0.389965   2.47486    -1.00073    0.733181   0.224016
  0.776375   0.0642885  -0.381338  -0.842996  -0.111027

julia> daqchannels(X)
4-element Vector{String}:
 "E1"
 "E2"
 "E3"
 "E4"

julia> X["E2",1]
0.16622444557689256

```

"""
function MeasData(devname, devtype, sampling::S,
                  data::AbstractMatrix{T},
                  chans::CH, units::Vector{String}) where {T,S<:AbstractDaqSampling,
                                                           CH}
    
    nch = size(data, 1)
    
    nch == numchannels(chans) ||
        error("Incompatible dimensions between data, channels and units!")

    numsamples(sampling) == size(data,2) ||
        error("Number of samples in sampling different from the number of lines of data array")
    
    MeasData{T,typeof(data),S,CH}(devname, devtype, sampling, data, chans, units)
end

MeasData(devname, devtype, sampling, data, chans, units::AbstractString) =
    MeasData(devname, devtype, sampling, data, chans,
             [string(units) for i in 1:numchannels(chans)])


MeasData(devname, devtype, sampling, data, chans) =
    MeasData(devname, devtype, sampling, data, chans,
             ["" for i in 1:numchannels(chans)])

function MeasData(devname, devtype, sampling::S,
                  data::AbstractMatrix{T}) where {T,S<:AbstractDaqSampling} 
    nchans = size(data,1)
    return MeasData(devname, devtype, sampling, data, nchans, fill("",4))
end

numsamples(d::MeasData{T,AT,S,CH}) where {T,AT<:AbstractMatrix{T},S,CH} =
    size(d.data,2)



"Device name that acquired the data"
devname(d::MeasData) = d.devname

"Device type that acquired the data"
devtype(d::MeasData) = d.devtype

"When did the data acquisition take place?"
daqtime(d::AbstractMeasData) = daqtime(d.sampling)

"What was the sampling rate of the data acquisition?"
samplingrate(d::MeasData) = samplingrate(d.sampling)
samplingtimes(d::MeasData) = samplingtimes(d.sampling)
samplinghours(d::MeasData) = samplinghours(d.sampling)
samplingperiod(d::MeasData) = samplingperiod(d.sampling)
daqtime(d::MeasData) = daqtime(d.sampling)

"Access to the data acquired"
measdata(d::MeasData) = d.data
daqchannels(d::MeasData) = daqchannels(d.chans)
numchannels(d::MeasData) = numchannels(d.chans)

import Base.getindex


getindex(d::MeasData{T,AT}, i::Integer, k::Integer) where {T,AT<:AbstractMatrix{T}} =
    d.data[i,k]


getindex(d::MeasData{T,AT}, idx...) where {T,AT<:AbstractArray{T}} =
    view(d.data, idx...)

"Access the data in channel name `ch`"
getindex(d::MeasData{T,AT}, ch::AbstractString) where {T,AT<:AbstractMatrix{T}} =
    view(d.data,chanindex(d.chans, ch),:)

"Access the data in channel index `i`"
getindex(d::MeasData{T,AT}, i::Int) where {T,AT<:AbstractMatrix{T}} =
    view(d.data, i, :)

"Access the data in channel name `ch` at time index `k`"
getindex(d::MeasData{T,AT}, ch::AbstractString,
         k::Integer) where {T,AT<:AbstractMatrix{T}} =
             d.data[chanindex(d.chans, ch),k]

function getindex(d::MeasData{T,AT},
                  chans::AbstractVector{<:AbstractString}) where {T,AT<:AbstractMatrix{T}}
    view(d.data, [chanindex(d.chans, ch) for ch in chans], :)
end

function getindex(d::MeasData{T,AT}, chans::AbstractVector{<:AbstractString},
                  k) where {T,AT<:AbstractMatrix{T}}
    view(d.data, [chanindex(d.chans, ch) for ch in chans], k)
end

function getindex(d::MeasData{T,AT},
                  chans::AbstractVector{<:Integer}) where {T,AT<:AbstractMatrix{T}}
    view(d.data, chans, :)
end


getindex(d::MeasData) = d.data



function chanslice(d::MeasData{T,AT},
                   idx::AbstractVector) where {T,AT<:AbstractMatrix{T}}
    ch = chanslice(d.chans, idx)
    MeasData(d.devname, d.devtype, d.sampling, d.data[idx,:], ch)
end


import Base.size

size(d::MeasData) = size(d.data)
size(d::MeasData, idx) = size(d.data, idx)

daqunits(d::MeasData) = d.units
daqunit(d::MeasData, ch) = d.units[chanindex(d.chans, ch)]
