
import DataStructures: OrderedDict
export AbstractDaqChannels, DaqChannels, numchannels, daqchannels, physchans
export chanslice, daqchan, chanindex

mutable struct DaqChannel{C} <: AbstractChannel
    "Index of the channel"
    idx::Int64
    "Name of the channel"
    name::Symbol
    "Description of the channel"
    descr::String
    "Unit of the data returned by the channel"
    unit::String
    "Physical channel on the device"
    physchan::C
end

"Index of the channel"
chanidx(ch::DaqChannel) = ch.idx

"Name of the channel"
channame(ch::DaqChannel) = ch.name

"Description of the channel"
chandescr(ch::DaqChannel) = ch.descr

"Unit of the data of the channel"
chanunit(ch::DaqChannel) = ch.unit

"Corresponding physical channel"
chanphys(ch::DaqChannel) = ch.physchan


mutable struct DaqChannelList{C,Ch}
    "Physical designation of the channels"
    physchans::C
    "Names of the channels"
    channels::Vector{DaqChannel{Ch}}
    "Mapping of channel names to index"
    chanmap::OrderedDict{Symbol,Int64}
end

# We dont want to broadcast over DaqChannels objects
Broadcast.broadcastable(ch::DaqChannels) = Ref(ch)

"""
`DaqChannels(channels::AbstractVector,  physchans)`
`DaqChannels(ch::Union{Symbol,Char,AbstractString}, nchans::Integer, physchans)`

Creates channel definition data structures for DAQ systems.

Usually, each input device can acquire data in different channels. Each channel has a
name (`String`) and an index, usually this index refers to the row of the matrix
containing data acquired. The name and/or index can be used to refer the a specific
channel of an input device.

The names of the channels is given by field `channels` and
`chanmap` is used to retrieve the channel index from its name.

The `physchans` field is how the device references to the channels using the nomenclature
of the input device itself. Take NIDAQmx as an example. When defining channels,
each channel is referenced by something like "dev1/ai3". While it is clear what is meant,
 analog input channel 3 from device 1, it is not a very nice reference.
These channel definitions are stored for reading and writing purpososes. The exact format
of the `physchans` will be device specific.

Method [`numchannels`](@ref) return the number of channels configure and [`daqchannels`](@ref)
returns the names of the channels. Methods [`getindex`](@ref) were implemented so that the index
of the channel name can be retrieved (when the argument is a string) or the channel name
corresponding to an index (when the argument is an integer) is desired.

If this `struct` does not satisfy the needs of a specific device or situation, other types,
inheriting `AbstractDaqChannels` can be implemented.


## Arguments

 * `physchans`: Physical definition of the channels as used in the device driver
 * `channels`: Vector with the name used by DAQJulia of each channel.
 * `ch`: A string used to prefix the index of the channels to get the channel names.
 * `nchans`: Number of channels

## Examples
```julia-repl
julia> ch = DaqChannels("E", 4)
DaqChannels{String}("test", "TestDevice", "", ["E1", "E2", "E3", "E4"], OrderedCollections.OrderedDict("E1" => 1, "E2" => 2, "E3" => 3, "E4" => 4), "")

julia> numchannels(ch)
4

julia> daqchannels(ch)
4-element Vector{String}:
 "E1"
 "E2"
 "E3"
 "E4"

julia> ch2 = DaqChannels(["E01", "E02", "E03", "E04"], "dev1/ai0:3")
DaqChannels{String}("dev1/ai0:3", ["E01", "E02", "E03", "E04"], OrderedCollections.OrderedDict("E01" => 1, "E02" => 2, "E03" => 3, "E04" => 4))

julia> numchannels(ch2)
4

julia> daqchannels(ch2)
4-element Vector{String}:
 "E01"
 "E02"
 "E03"
 "E04"

julia> physchans(ch2)
"dev1/ai0:3"
```
"""
function DaqChannels(channels::AbstractVector, physchans="")
    nch = length(channels)
    
    chans = string.(channels)

    chanmap = chanlist2map(chans)

    return DaqChannels(physchans, chans, chanmap)
end
import Base.*
function DaqChannels(ch::Union{Symbol,Char,AbstractString},
                     nchans::Integer, physchans="")
    nd = numdigits(nchans) 
    chans = [string(ch, s) for s in numstring.(1:nchans, nd)]
    return DaqChannels(chans, physchans)
end

DaqChannels(N::Integer) = DaqChannels(1:N, "")


"""
`chanlist2map(chans)`

Turns a list of channel names into a map from
channel name (string) to channel index (integer).

If there are repeated channel names, unknown behaviour.
"""
function chanlist2map(chans::AbstractVector{CH}, ::Type{TD}=OrderedDict) where {CH,TD<:AbstractDict}
    chanmap = TD{Symbol,Int}()
    for (i,v) in enumerate(chans)
        chanmap[Symbol(v)] = i
    end
    return chanmap
end

        


"Return the number of channels of an input device"
nchannels(ch::DaqChannels) = length(ch.channels)


"Return channel names of every configure channel"
daqchannels(ch::DaqChannels) = ch.channels

"Return the physical channel description of the channels"
physchans(ch::DaqChannels) = ch.physchans

import Base.getindex
getindex(ch::DaqChannels, s) = ch.channels[ch.chanmap[Symbol(s)]]
getindex(ch::DaqChannels, idx::Integer) = ch.channels[idx]

"""
`chanslice(ch::DaqChannels, idx::AbstractVector{<:Integer})`

Returns a channel object containing the channels specified by `idx`.
"""
function chanslice(ch::DaqChannels{C}, idx::AbstractVector{<:Integer}) where {C}
                                                                                
    chans = ch.channels[idx]
    chanmap = OrderedDict{String,Int}()
    for (i,ch) in enumerate(chans)
        chanmap[ch] = i
    end

    return DaqChannels("", chans, chanmap)
end


function chanslice(ch::DaqChannels{C},
                   chans::AbstractVector{<:AbstractString}) where {C}
    
    idx = [ch.chanmap[k] for k in chans]
    return chanslice(ch, idx)
end

import Base.setindex!
function setindex!(ch::DaqChannels, chan::AbstractString, idx::Integer)
    chold = ch.channels[idx]
    delete!(ch.chanmap, chold)
    ch.chanmap[chan] = idx
    ch.channels[idx] = chan
    return chan                
end

daqchan(ch::DaqChannels, i::Integer) = ch.channels[i]

"""
`chanindex(ch, chan)`

Returns the index of channel `chan`
"""
chanindex(ch::DaqChannels, chan::AbstractString) = ch.chanmap[chan]
chanindex(ch::DaqChannels, chan::Integer) = chan


# We can use other structures as channels.
# An integer can be used: it just means that the channels are a range from 1:N
# An array of strings can also be used. Or an array of integers

numchannels(N::Integer) = N
daqchannels(N::Integer) = string.(1:N)

numchannels(ch::AbstractVector) = length(ch)
daqchannels(ch::AbstractVector{<:AbstractString}) = ch
daqchannels(ch::AbstractVector{<:Integer}) = string.(ch)

chanslice(ch::Integer, chans) = (1:ch)[chans]
chanslice(ch::AbstractVector, chans::AbstractVector{<:Integer}) = ch[chans]
chanslice(ch::AbstractVector, chans::AbstractVector{<:AbstractString}) =
    ch[ [chanindex(ch, ichan) for ichan in chans] ]

daqchan(N::Integer, i::Integer) = (i <= N) ? string(i) : error("Channel $i not available in $N channels!")

daqchan(ch::AbstractVector{<:AbstractString}, i::Integer) = ch[i]
daqchan(ch::AbstractVector, i::Integer) = string(ch[i])

function chanindex(N::Integer, chan::AbstractString)
    ichan = parse(Int, chan)
    return chanindex(N, ichan)
end

chanindex(N::Integer, i::Integer) = (1 ≤ i ≤ N) ? i : error("Channel $chan not available in range 1:$N!")

chanindex(ch::AbstractVector{<:Integer}, chan::AbstractString) = chanindex(ch, parse(Int, chan))

function chanindex(ch::AbstractVector{<:Integer}, chan::Integer)
    idx = findfirst(isequal(chan), ch)
    return !isnothing(idx) ? idx : error("Channel $chan not found!")
end

function chanindex(ch::AbstractVector{<:AbstractString}, chan::AbstractString)
    idx = findfirst(isequal(chan), ch)

    return !isnothing(idx) ? idx : error("Channel $chan not found!")
end
    
                               


