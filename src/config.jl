

import DataStructures: OrderedDict
export AbstractDaqConfig, DaqConfig
export iparam, iparam!, fparam, fparam!, sparam, sparam!, oparam, oparam!
export daqdevip, daqdevport, daqdevmodel, daqdevserial, daqdevtag

abstract type AbstractDaqConfig end

mutable struct DaqConfig <: AbstractDaqConfig
    "Device name"
    devname::String
    "Device type"
    devtype::String
    "IP address of the computer where the device is located"
    ip::String
    "Port number of device"
    port::Int
    "Model of the device"
    model::String
    "Serial number of the device"
    sn::String
    "Storage tag of the device"
    tag::String
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
"Retrieve device IP address"
daqdevip(dconf::DaqConfig) = dconf.ip
"Retrieve device model"
daqdevport(dconf::DaqConfig) = dconf.port
"Retrieve device model"
daqdevmodel(dconf::DaqConfig) = dconf.model
"Retrieve device serial number"
daqdevserial(dconf::DaqConfig) = dconf.sn
"Retrieve device tag"
daqdevtag(dconf::DaqConfig) = dconf.tag


"Retrieve device IP address"
daqdevip(dev::AbstractDevice) = dev.conf.ip
"Retrieve device model"
daqdevport(dev::AbstractDevice) = dev.conf.port
"Retrieve device model"
daqdevmodel(dev::AbstractDevice) = dev.conf.model
"Retrieve device serial number"
daqdevserial(dev::AbstractDevice) = dev.conf.sn
"Retrieve device tag"
daqdevtag(dev::AbstractDevice) = dev.conf.tag


function DaqConfig(devname, devtype; ip="", port=0, model="", sn="", tag="", kw...)

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

    return DaqConfig(devname, devtype, ip, port, model, sn, tag,
                     iparams, fparams, sparams, oparams)
           
            
end

function Base.copy(c::DaqConfig)
    # Let's start by copying all parameters from conf
    c1 = DaqConfig(c.devname, c.devtype; ip=c.ip, port=c.port, model=c.model,
                 sn=c.sn, tag=c.tag)
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



