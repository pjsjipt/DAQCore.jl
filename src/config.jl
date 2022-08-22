

import DataStructures: OrderedDict
export AbstractDaqConfig, DaqConfig
export iparam, iparam!, fparam, fparam!, sparam, sparam!, oparam, oparam!
export ihaskey, fhaskey, shaskey, ohaskey

abstract type AbstractDaqConfig end

mutable struct DaqConfig <: AbstractDaqConfig
    "Device name"
    devname::String
    "Device type"
    devtype::String
    "Integer configuration parameters of the device"
    iparams::OrderedDict{String,Int64}
    "Floating point configuration parameters of the device"
    fparams::OrderedDict{String,Float64}
    "String configuration parameters of the device"
    sparams::OrderedDict{String,String}
    "Other parameters in other formats"
    oparams::OrderedDict{String,Any}
end

devname(c::DaqConfig) = c.devname
devtype(c::DaqConfig) = c.devtype


function DaqConfig(devname, devtype; kw...)

    fparams = OrderedDict{String,Float64}()
    iparams = OrderedDict{String,Int64}()
    sparams = OrderedDict{String,String}()
    oparams = OrderedDict{String,Any}()

    for (k,v) in kw
        ks = string(k)
        if isa(v, Integer)
            iparams[ks] = Int64(v)
        elseif isa(v, AbstractFloat)
            fparams[ks] = Float64(v)
        elseif isa(v, Union{AbstractString,AbstractChar,Symbol}) # Let's try a string...
            sparams[ks] = string(v)
        else # Anything else
            oparams[ks] = v
        end
    end

    return DaqConfig(devname, devtype, iparams, fparams, sparams, oparams)
           
            
end

function Base.copy(c::DaqConfig)
    # Let's start by copying all parameters from conf
    c1 = DaqConfig(c.devname, c.devtype)
    c1.iparams = copy(c.iparams)
    c1.fparams = copy(c.fparams)
    c1.sparams = copy(c.sparams)
    c1.oparams = deepcopy(c.oparams)
    return c1
    
end

"Retrieve integer configuration parameter"
iparam(dconf::DaqConfig, param) = dconf.iparams[param]
"Retrieve string configuration parameter"
sparam(dconf::DaqConfig, param) = dconf.sparams[param]
"Retrieve float configuration parameter"
fparam(dconf::DaqConfig, param) = dconf.fparams[param]
"Retrieve other configuration parameters types"
oparam(dconf::DaqConfig, param) = dconf.oparams[param]

"Do integer parameters have key `param`?"
ihaskey(c::DaqConfig, param) = haskey(c.iparams, param)
"Do float parameters have key `param`?"
fhaskey(c::DaqConfig, param) = haskey(c.fparams, param)
"Do string parameters have key `param`?"
shaskey(c::DaqConfig, param) = haskey(c.sparams, param)
"Do `Any` parameters have key `param`?"
ohaskey(c::DaqConfig, param) = haskey(c.oparams, param)


iparam!(dconf::DaqConfig, param::AbstractString, val) =
    dconf.iparams[string(param)] = Int64(val)
function iparam!(dconf::DaqConfig, plst...)
    for (k,v) in plst
        dconf.iparams[string(k)] = Int64(v)
    end
end


                 
fparam!(dconf::DaqConfig, param::AbstractString, val) = 
    dconf.fparams[string(param)] = Float64(val)

function fparam!(dconf::DaqConfig, plst...)
    for (k,v) in plst
        dconf.fparams[string(k)] = Float64(v)
    end
end

sparam!(dconf::DaqConfig, param::AbstractString, val) =
    dconf.sparams[string(param)] = string(val)

function sparam!(dconf::DaqConfig, plst...)
    for (k,v) in plst
        dconf.sparams[string(k)] = string(v)
    end
end

oparam!(dconf::DaqConfig, param::AbstractString, val::Any) = dconf.oparams[param] = val

function oparam!(dconf::DaqConfig, plst...)
    for (k,v) in plst
        dconf.oparams[string(k)] = v
    end
end


# Lets extend this to any device. If it has a conf field, it can be used
iparam(dev::AbstractDevice, param) = iparam(dev.conf, param)
fparam(dev::AbstractDevice, param) = fparam(dev.conf, param)
sparam(dev::AbstractDevice, param) = sparam(dev.conf, param)
oparam(dev::AbstractDevice, param) = oparam(dev.conf, param)

ihaskey(dev::AbstractDevice, param) = ihaskey(dev.conf, param)
fhaskey(dev::AbstractDevice, param) = fhaskey(dev.conf, param)
shaskey(dev::AbstractDevice, param) = shaskey(dev.conf, param)
ohaskey(dev::AbstractDevice, param) = ohaskey(dev.conf, param)

iparam!(dev::AbstractDevice, param::AbstractString, val) =
    iparam!(dev.conf, param, val)

fparam!(dev::AbstractDevice, param::AbstractString, val) =
    fparam!(dev.conf, param, val)

sparam!(dev::AbstractDevice, param::AbstractString, val) =
    sparam!(dev.conf, param, val)

oparam!(dev::AbstractDevice, param::AbstractString, val) =
    oparam!(dev.conf, param, val)

iparam!(dev::AbstractDevice, plst...) = iparam!(dev.conf, plst...)
fparam!(dev::AbstractDevice, plst...) = fparam!(dev.conf, plst...)
sparam!(dev::AbstractDevice, plst...) = sparam!(dev.conf, plst...)
oparam!(dev::AbstractDevice, plst...) = oparam!(dev.conf, plst...)

import Base.setindex!

setindex!(dconf::DaqConfig, val::Integer, param) = iparam!(dconf, string(param), val)
setindex!(dconf::DaqConfig, val::AbstractFloat, param) =
    fparam!(dconf, string(param), Float64(val))
setindex!(dconf::DaqConfig, val::Union{AbstractString,Symbol,Char}, param) =
    sparam!(dconf, string(param), string(val))
setindex!(dconf::DaqConfig, val::Any, param) = oparam!(dconf, string(param), val)



