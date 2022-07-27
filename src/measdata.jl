
using Dates
export MeasData

"Base type for measurement data sets"
abstract type AbstractMeasData end


"""
`MeasData`

Structure to store data acquired from a DAQ device. It also stores metadata related to 
the DAQ device, data acquisition process and daq channels.
"""
mutable struct MeasData{T,AT} <: AbstractMeasData
    "Device that generated the data"
    devname::String
    "Type of device"
    devtype::String
    "Time of data aquisition"
    time::DateTime
    "Sampling rate (Hz)"
    rate::Float64
    "Data acquired"
    data::AT
    channels::OrderedDict{String,Int}
    "Units"
    units::Vector{String}
end

function MeasData(devname, devtype, time, rate, data::AbstractMatrix{T},
                  channels, units) where {T}
    nch = size(data, 1)
    nd = floor(Int, log10(nch)) + 1
    
    chans = OrderedDict{String,Int}()
    if isnothing(channels)
        for i in 1:nch
            s = "C" * numstring(i, nd)
            chans[s] = i
        end
    elseif isa(channels, AbstractString) || isa(channels, Symbol)
        c = string(channels)
        for i in 1:nch
            chans[c * numstring(i,nd)] = i
        end
    elseif isa(channels, AbstractVector)
        if length(channels) != nch
            error("Length of parameters `channels` should be the same as the number of rows o data measurement matrix!")
        end
        
        for (i,v) in enumerate(channels)
            chans[string(v)] = i
        end
    else
        error("Can not handle $(typeof(channels)) for `channels` parameter")
    end
    
    if isnothing(units)
        uns = fill("", nch)
    elseif isa(units, AbstractString) || isa(units, Symbol)
        uns = fill(string(units), nch)
    elseif isa(units, AbstractVector)
        if length(units) != nch
            error("Length of parameters `channels` should be the same as the number of rows o data measurement matrix!")
        end
        uns = string.(units)
    else
        error("Can not handle $(typeof(units)) for `units` parameter")
    end
    MeasData{T,typeof(data)}(devname, devtype, time, rate, data, chans, uns)
end


function MeasData(devname::String, devtype::String, time::DateTime,
                  rate::Float64, data::AbstractMatrix{T},
                  channels::OrderedDict{String,Int},
                  units::Vector{String}) where {T}
    if !(size(data,1) == length(channels) == length(units))
        error("Incompatible `data`, `channels` and `units`!")
    end
    return MeasData{T}(devname, devtype, time, rate, data, channels, units)
end


function MeasData(devname, devtype, data::AbstractMatrix{T};
                  time=now(), rate=1.0, channels="C", units="") where {T}
    return MeasData{T}(devname, devtype, time, rate, data, channels, units)
end

    
#MeasData(devname, devtype, time, rate, data, chan
#DateTime(Dates.UTInstant(Millisecond(d.t)))
"Convert a DateTime object to ms"
time2ms(t::DateTime) = t.instant.periods.value
"Convert a time in ms to DateTimeObject"
ms2time(ms::Int64) = DateTime(Dates.UTInstant{Millisecond}(Millisecond(ms)))

"Device name that acquired the data"
devname(d::MeasData) = d.devname

"Device type that acquired the data"
devtype(d::MeasData) = d.devtype

"When did the data acquisition take place?"
meastime(d::AbstractMeasData) = d.time

"What was the sampling rate of the data acquisition?"
samplingrate(d::MeasData) = d.rate

"Access to the data acquired"
measdata(d::MeasData) = d.data
daqchannels(d::MeasData) = collect(keys(d.chans))
    
import Base.getindex

getindex(d::MeasData, idx...) = view(d.data, idx...)

"Access the data in channel name `ch`"
getindex(d::MeasData,ch::AbstractString) = view(d.data,d.channels[ch],:)

"Access the data in channel index `i`"
getindex(d::MeasData, i::Integer)  = view(d.data, i, :)

"Access the data in channel name `ch` at time index `k`"
getindex(d::MeasData, ch::AbstractString,k::Integer) =
    d.data[d.channels[ch],k]

function getindex(d::MeasData, chans::AbstractVector{<:AbstractString})
    view(d.data, [d.channels[ch] for ch in chans], :)
end

function getindex(d::MeasData, chans::AbstractVector{<:AbstractString}, k)
    view(d.data, [d.channels[ch] for ch in chans], k)
end

function getindex(d::MeasData, chans::AbstractVector{<:Integer})
    view(d.data, chans, :)
end

getindex(d::MeasData) = d.data

                
