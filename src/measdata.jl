
using Dates
export MeasData, meastime, measdata, samplingrate

"Base type for measurement data sets"
abstract type AbstractMeasData end


"""
`MeasData`

Structure to store data acquired from a DAQ device. It also stores metadata related to 
the DAQ device, data acquisition process and daq channels.
"""
mutable struct MeasData{T,AT,CH} <: AbstractMeasData
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
    "Channel Information"
    chans::CH
end

function MeasData(devname, devtype, time, rate,
                  data::AbstractMatrix{T}, chans::CH) where {T,CH<:AbstractDaqChannels}
    nch = size(data, 1)
    
    nch == numchannels(chans) ||
        error("Incompatible dimensions between data, channels and units!")
    
    MeasData{T,typeof(data),CH}(devname, devtype, time, rate,
                                data, channels)
end




#MeasData(devname, devtype, time, rate, data, chan
#DateTime(Dates.UTInstant(Millisecond(d.t)))

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
daqchannels(d::MeasData) = daqchannels(d.chans)
numchannels(d::MeasData) = numchannels(d.chans)


import Base.getindex

getindex(d::MeasData, idx...) = view(d.data, idx...)

"Access the data in channel name `ch`"
getindex(d::MeasData,ch::AbstractString) = view(d.data,d.chans[ch],:)

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

                
