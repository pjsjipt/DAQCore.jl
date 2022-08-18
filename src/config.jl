

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


"Retrieve integer configuration parameter"
iparam(dconf::DaqConfig, param) = dconf.iparams[param]
"Retrieve string configuration parameter"
sparam(dconf::DaqConfig, param) = dconf.sparams[param]
"Retrieve float configuration parameter"
fparam(dconf::DaqConfig, param) = dconf.fparams[param]
"Retrieve other configuration parameters types"
oparam(dconf::DaqConfig, param) = dconf.oparams[param]

iparam!(dconf::DaqConfig, param, val::Integer) =
    dconf.iparams[string(param)] = Int64(val)
fparam!(dconf::DaqConfig, param, val::AbstractFloat) =
    dconf.fparams[string(param)] = Float64(val)
sparam!(dconf::DaqConfig, param, val::Union{AbstractString,Symbol,Char}) =
    dconf.sparams[string(param)] = string(val)
oparam!(dconf::DaqConfig, param, val::Any) = dconf.oparams[param] = val

import Base.setindex!

setindex!(dconf::DaqConfig, val::Integer, param) = iparam!(dconf, string(param), val)
setindex!(dconf::DaqConfig, val::AbstractFloat, param) =
    fparam!(dconf, string(param), Float64(val))
setindex!(dconf::DaqConfig, val::Union{AbstractString,Symbol,Char}, param) =
    sparam!(dconf, string(param), string(val))
setindex!(dconf::DaqConfig, val::Any, param) = oparam!(dconf, string(param), val)



