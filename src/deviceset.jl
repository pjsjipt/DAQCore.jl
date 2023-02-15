# Several devices together

export DeviceSet, MeasDataSet

mutable struct DeviceSet{DevList} <: AbstractInputDev
    "Device name associated to this `DeviceSet`"
    devname::String
    "Index of most relevant measurement device"
    iref::Int
    "List of devices"
    devices::DevList
    "Map from device name to device index in `devices`."
    devdict::OrderedDict{String,Int}
    time::DateTime
end

"""
`DeviceSet(dname, devices::DevList, iref=1)`

Create a meta device that handles data acquisition from several independent interfaces.

The `devices` argument specifies the individual DAQ devices that are used. It could
be a tuple (recommended) or a vector of AbstractInputDev.

The argument `iref` corresponds to the reference device (if it exists). 
This reference device is simply the device that is used when checking whether
 data acquisition is ongoing or how many samples have been read.

As is usually the case, there should be a unique `devname` associated with
each `DeviceSet` object.

Individual devices have channels and method [`daqchannels`](@ref) can be used to get
the names of each channel. Since different devices in a `DeviceSet` can have the same
channels, the complete characterization of a channel should have the specific device
name (`devname` field) attached to it, therefore each channel will be a vector of
character strings.

Most data acquisition functions work with `DeviceSet` objects. One difference here
is that the return value of [`daqacquire`](@ref) and [`daqread`](@ref) is no longer
a [`MeasData`](@ref) but instead it is a [`MeasDataSet`](@ref) that contains the
data acquired by each individual device. See example below and the documentation for
[`MeasDataSet`](@ref) on how to access the data.


## Examples

```julia-repl
julia> dev1 = TestDaq("Device1");

julia> dev2 = TestDaq("Device2");

julia> daqaddinput(dev1, ["E1", "E2"]);

julia> daqaddinput(dev2, ["P1", "P2"]);

julia> dev = DeviceSet("devices", (dev1, dev2));

julia> daqchannels(dev1)
2-element Vector{String}:
 "E1"
 "E2"

julia> daqchannels(dev2)
2-element Vector{String}:
 "P1"
 "P2"

julia> daqchannels(dev)
4-element Vector{Vector{String}}:
 ["Device1", "E1"]
 ["Device1", "E2"]
 ["Device2", "P1"]
 ["Device2", "P2"]

julia> X = daqacquire(dev);

julia> typeof(X)
MeasDataSet{Vector{MeasData}}
```
"""
function DeviceSet(dname, devices::DevList, iref=1) where {DevList}

    devdict = OrderedDict{String,Int}()
    ndev = length(devices)
    for (i, dev) in enumerate(devices)
        devdict[devname(dev)] = i
    end
    
    return DeviceSet(dname, iref, devices, devdict, now())
end


import Base.getindex

"""
`dev[i]`

Return the `i`-th device of a device set
"""
getindex(dev::DeviceSet, i) = dev.devices[i]
getindex(dev::DeviceSet, dname::AbstractString) = dev.devices[dev.devdict[dname]]

numchannels(d::DeviceSet) = sum(numchannels(d) for d in d.devices)

function daqchannels(d::DeviceSet)
    chans = Tuple{String,Int}}[]
    for dev in d.devices
        devchans = daqchannels(dev)
        dname = devname(dev)
        for c in devchans
            push!(chans, [dname, c])
        end
    end
    return chans
end

struct MeasDataSet{MeasSet} <: AbstractMeasData
    "Device name"
    devname::String
    "Device type (`DeviceSet`)"
    devtype::String
    "Data acquisition time"
    time::DateTime
    "Data acquired by each device in the `DeviceSet`"
    data::MeasSet
    "Map from device name to device index in `devices`."
    devdict::OrderedDict{String,Int}
end

"""
`MeasDataSet(devname, devtype, time, data)`

Stores the data acquired by a [`DeviceSet`](@ref). It is basically a strucure made up
of individiaul measurement data from each device in the the [`DeviceSet`](@ref).

To access data, [`Base.getindex`](@ref) is used. But in this case, the device name is
used as a first dimension. See example below.

## Examples

```julia-repl
julia> dev1 = TestDaq("Device1");

julia> dev2 = TestDaq("Device2");

julia> daqaddinput(dev1, ["E1", "E2"]);

julia> daqaddinput(dev2, ["P1", "P2"]);

julia> dev = DeviceSet("devices", (dev1, dev2));

julia> daqchannels(dev1)
2-element Vector{String}:
 "E1"
 "E2"

julia> daqchannels(dev2)
2-element Vector{String}:
 "P1"
 "P2"

julia> daqchannels(dev)
4-element Vector{Vector{String}}:
 ["Device1", "E1"]
 ["Device1", "E2"]
 ["Device2", "P1"]
 ["Device2", "P2"]

julia> X = daqacquire(dev);

julia> typeof(X)
MeasDataSet{Vector{MeasData}}

julia> daqchannels(X)
4-element Vector{Vector{String}}:
 ["Device1", "E1"]
 ["Device1", "E2"]
 ["Device2", "P1"]
 ["Device2", "P2"]

julia> e1 = X["Device1", "E1"]; # accessing channel E1 of Device1

julia> e1b = X[1, 1]; # accessing channel 1 of first device

julia> X["Device1", "E1",10] # accessing 10th sample from channel E1 of Device1
0.41221474770752664

```

"""
function MeasDataSet(dname, devtype, time, datasets)

    devdict = OrderedDict{String,Int}()
    for (i,d) in enumerate(datasets)
        devdict[devname(d)] = i
    end
    return MeasDataSet(dname, devtype, time, datasets, devdict)
end

"""
`devname(d::MeasDataSet)`

Return the device name that acquired the data.
"""
devname(d::MeasDataSet) = d.devname

"""
`devtype(d::MeasDataSet)`

Return the device type that acquired the data ([`DeviceSet`](@ref) in this case).
"""
devtype(d::MeasDataSet) = d.devtype

"""
`meastime(d::MeasDataSet)`

Return the [`DateTime`](@ref) when the device started to acquire the data from 
a [`DeviceSet`](@ref).
"""
daqtime(d::MeasDataSet) = d.time

"""
`d["some/path/to/measurements"]`

Retrieve data acquired stored in a [`MeasDataSet`](@ref).

The data,  in this case, was acquired by several devices that 
make up a [`DeviceSet](@ref). Thus sub-device might be another [`MeasDataSet`](@ref)
or, more commonly, a [`MeasData`](@ref) structure. 

As an example, imagine that the [`DeviceSet`](@ref) is madeup of `dev1` and `dev2` 
devices. 

```
d["dev1"]
``` 

returns the data acquired by `dev1`. To get a specific channel, you can use

```
d["dev1/chanx"]
```

and this will return the value stored by channel `chanx` of `dev1`.

The channel can be specified independently as in the following example:

```
d["dev1", "chanx"]
```

or it can be specified by index:

```
d["dev1", 3]
```

(assuming `chanx` corresponds do channel 3)

In both of last cases, the indexing is forwarded to the `getindex` method for
[`MeasData`](@ref) for data retrieval.

"""
getindex(d::MeasDataSet, idx::Integer) = d.data[idx]
getindex(d::MeasDataSet, dname::AbstractString) = d.data[d.devdict[dname]]

getindex(d::MeasDataSet, devchan::Tuple{<:AbstractString,T}) where {T} =
    d[d.devdict[devchan[1]]][devchan[2]]
getindex(d::MeasDataSet, devchan::Tuple{<:Integer,T}) where {T} =
    d[devchan[1]][devchan[2]]




numchannels(d::MeasDataSet) = sum(numchannels(d) for d in d.data)

"""
`daqchannels(d::MeasDataSet)`

Return channel names associated with each device that is acquiring data. 
The device name is prepended to the channel name separated by a '/'.
"""
function daqchannels(d::MeasDataSet)
    chans = Vector{String}[]
    for data in d.data
        devchans = daqchannels(data)
        dname = devname(data)
        for c in devchans
            push!(chans, [dname, c])
        end
    end
    return chans
end



"""
`daqstart(devs::DeviceSet)`

Start asynchrohous data acquisition on every device.
"""
function daqstart(devs::DeviceSet)
    devs.time = now()
    for dev in devs.devices
        daqstart(dev)
    end
    return
end

"""
`daqread(devs::DeviceSet)`

Read the data from every device in `DeviceSet`. It stores this data in a dictionary
where the key is the device name and the value is the data.
"""
function daqread(devs::DeviceSet)
    #data = OrderedDict{String,MeasData}()
    data = MeasData[]
    for dev in devs.devices
        push!(data, daqread(dev))
    end
    return MeasDataSet(devname(devs), "DeviceSet", devs.time, data)
end

"""
`daqacquire(devs::DeviceSet)`

Execute a synchronous data acquisition of every device.
"""
function daqacquire(devs::DeviceSet)
    devs.time = now()
    daqstart(devs)
    return daqread(devs)
end

function daqstop(devs::DeviceSet)
    for dev in devs.devices
        daqstop(dev)
    end
end

#import Base.getindex
#Base.getindex
samplesread(devs::DeviceSet) = samplesread(devs.devices[devs.iref])
isreading(devs::DeviceSet) = isreading(dev.devices[devs.iref])
isdaqfinished(devs::DeviceSet) = isdaqfinished(dev.devices[devs.iref])
issamplesavailable(devs::DeviceSet)=issamplesavailable(devs.devices[devs.iref])



        
