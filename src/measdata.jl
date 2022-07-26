
using Dates
export MeasData

"Base type for measurement data sets"
abstract type AbstractMeasData end


"""
`MeasData`

Structure to store data acquired from a DAQ device. It also stores metadata related to 
the DAQ device, data acquisition process and daq channels.
"""
struct MeasData{T, AT, C, U} <: AbstractMeasData
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
    channels::C
    "Units"
    units::U
end

function MeasData(devname, devtype, time, rate, data::AbstractMatrix{T},
                  channels::AbstractVector{String}, units::AbstractVector{String}) where {T}
    nch = size(data, 1)

    if nch != length(channels) 
        error("The number of channels must be equal to the number of rows in data matrix!")
    end
    if nch != nch != length(units)
        error("The number of units must be equal to the number of rows in data matrix!")
    end
           
    return MeasData{T, typeof(data), typeof(channels), typeof(units)}(devname, devtype, time,
                                                                   rate, data, channels, units)
end

function MeasData(devname, devtype, data::AbstractMatrix{T}; time=now(), rate=1.0,
                  channels=nothing, units=nothing) where {T}
    nch = size(data,1)
    
    if isnothing(channels)
        nd = floor(Int, log10(nch)) + 1
        chans = "C" .* numstring.(1:nch, nd)
    elseif !isa(channels, AbstractVector) 
        nd = floor(Int, log10(nch)) + 1
        chans = string(channels) .* numstring.(1:nch, nd)
    else
        chans = channels
    end

    if isnothing(units)
        un = fill("", nch)
    elseif !isa(units, AbstractVector)
        un = fill(string(units), nch)
    else
        un = units
    end
    
    return MeasData(devname, devtype, time, rate, data, chans, un)
end

    
#MeasData(devname, devtype, time, rate, data, chan
    
