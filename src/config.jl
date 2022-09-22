

import DataStructures: OrderedDict
export AbstractDaqConfig, DaqConfig
export iparam, iparam!, fparam, fparam!, sparam, sparam!, oparam, oparam!
export ihaskey, fhaskey, shaskey, ohaskey

abstract type AbstractDaqConfig end

mutable struct DaqConfig <: AbstractDaqConfig
    "Integer configuration parameters of the device"
    iparams::OrderedDict{String,Int64}
    "Floating point configuration parameters of the device"
    fparams::OrderedDict{String,Float64}
    "String configuration parameters of the device"
    sparams::OrderedDict{String,String}
    "Other parameters in other formats"
    oparams::OrderedDict{String,Any}
end


function DaqConfig(; kw...)

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

    return DaqConfig(iparams, fparams, sparams, oparams)
           
            
end

function Base.copy(c::DaqConfig)
    # Let's start by copying all parameters from conf
    iparams = copy(c.iparams)
    fparams = copy(c.fparams)
    sparams = copy(c.sparams)
    oparams = deepcopy(c.oparams)
    return DaqConfig(iparams, fparams, sparams, oparams)
    
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
iparam(dev::AbstractDevice, param) = iparam(dev.config, param)
fparam(dev::AbstractDevice, param) = fparam(dev.config, param)
sparam(dev::AbstractDevice, param) = sparam(dev.config, param)
oparam(dev::AbstractDevice, param) = oparam(dev.config, param)

ihaskey(dev::AbstractDevice, param) = ihaskey(dev.config, param)
fhaskey(dev::AbstractDevice, param) = fhaskey(dev.config, param)
shaskey(dev::AbstractDevice, param) = shaskey(dev.config, param)
ohaskey(dev::AbstractDevice, param) = ohaskey(dev.config, param)

iparam!(dev::AbstractDevice, param::AbstractString, val) =
    iparam!(dev.config, param, val)

fparam!(dev::AbstractDevice, param::AbstractString, val) =
    fparam!(dev.config, param, val)

sparam!(dev::AbstractDevice, param::AbstractString, val) =
    sparam!(dev.config, param, val)

oparam!(dev::AbstractDevice, param::AbstractString, val) =
    oparam!(dev.config, param, val)

iparam!(dev::AbstractDevice, plst...) = iparam!(dev.config, plst...)
fparam!(dev::AbstractDevice, plst...) = fparam!(dev.config, plst...)
sparam!(dev::AbstractDevice, plst...) = sparam!(dev.config, plst...)
oparam!(dev::AbstractDevice, plst...) = oparam!(dev.config, plst...)

import Base.setindex!

setindex!(dconf::DaqConfig, val::Integer, param) = iparam!(dconf, string(param), val)
setindex!(dconf::DaqConfig, val::AbstractFloat, param) =
    fparam!(dconf, string(param), Float64(val))
setindex!(dconf::DaqConfig, val::Union{AbstractString,Symbol,Char}, param) =
    sparam!(dconf, string(param), string(val))
setindex!(dconf::DaqConfig, val::Any, param) = oparam!(dconf, string(param), val)



