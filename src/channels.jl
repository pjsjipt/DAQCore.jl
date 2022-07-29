
import DataStructures: OrderedDict
export AbstractDaqChannels, DaqChannels

abstract type AbstractDaqChannels end

mutable struct DaqChannels{C} <: AbstractDaqChannels
    "Device name that contains the channels"
    devname::String
    "Type of device containing the channels"
    devtype::String
    "Physical designation of the channels"
    physchans::C
    "Names of the channels"
    channels::Vector{String}
    "Mapping of channel names to index"
    chanmap::OrderedDict{String,Int}
end
"""
`DaqChannels(devname, devtype, channels::AbstractVector)`
`DaqChannels(devname, devtype, ch::Union{Symbol,Char,AbstractString}, nchans::Integer)`
`DaqChannels(devname, devtype, physchans, channels::AbstractVector)`

Creates channel definition data structures for DAQ system.
In `DAQJulia`, the data of a channel acquired from a device can be referenced by an index,
basically the row in the data matrix or a name, a string that references said channel.
`DaqChannels` is a data structure that helps handling this.

As is the case almost everything in the `DAQJulia` ecossystem, a `DaqChannel` has a
`devname` and a `devtype`. The names of the channels is given by field `channels` and
`chanmap` is used to retrieve the channel index from its name.

The `physchans` field is how the device references to the channels. Take NIDAQmx as an
example. Whe defining channels, each channel is referenced by something like "dev1/ai3".
While it is clear what is meant - analog input channel 3 from device 1, it is not a very
nice reference. These channel definitions are stored for reading and writing purpososes.

## Arguments

 * `devname`: A string defining the device name in `DAQJulia`
 * `devtype`: A string defining the device type
 * `physchans`: Physical definition of the channels as used in the device driver
 * `channels`: Vector with the name used by DAQJulia of each channel.
 * `ch`: A string used to prefix the index of the channels to get the channel names.
 * `nchans`: Number of channels

"""
function DaqChannels(devname, devtype, channels::AbstractVector)
    nch = length(channels)
    
    chans = string.(channels)

    chanmap = OrderedDict{String,Int}()

    for (i,v) in chans
        chanmap[v] = i
    end

    return DaqChannels(devname, devtype, channels, chans, chanmap)
end

function DaqChannels(devname, devtype, ch::Union{Symbol,Char,AbstractString},
                     nchans::Integer)
    nd = floor(Int,log10(nchans)) + 1
    chans = string(ch) .* numstring.(1:nchans,nd)

    return DaqChannels(devname, devtype, chans)
end


                     
function DaqChannels(devname, devtype, physchans, channels::AbstractVector)
    nch = length(channels)
    
    chans = string.(channels)

    chanmap = OrderedDict{String,Int}()

    for (i,v) in chans
        chanmap[v] = i
    end

    return DaqChannels(devname, devtype, physchans, chans, chanmap)
end


devname(ch::DaqChannels) = ch.devname
devtype(ch::DaqChannels) = ch.devtype

numchannels(ch::DaqChannels) = length(ch.channels)
daqchannels(ch::DaqChannels) = ch.channels

import Base.getindex
getindex(ch::DaqChannels, s::AbstractString) = ch.chanmap[s]
getindex(ch::DaqChannels, idx::Integer) = ch.channels[idx]

