

import DataStructures: OrderedDict
export AbstractDaqConfig, DaqConfig

abstract type AbstractDaqConfig end

mutable struct DaqConfig <: AbstractDaqConfig
    "Device name"
    devname::String
    "Device type"
    devtype::String
    "IP address of the computer where the device is located"
    ip::String
    "Model of the device"
    model::String
    "Serial number of the device"
    sernum::String
    "Storage tag of the device"
    tag::String
    "Integer configuration parameters of the device"
    iparams::OrderedDict{String,Int64}
    "Floating point configuration parameters of the device"
    fparams::OrderedDict{String,Float64}
    "String configuration parameters of the device"
    sparams::OrderedDict{String,String}
end

function DaqConfig(devname, devtype; ip="", model="", sernum="", tag="", kw...)

    fparams = OrderedDict{String,Float64}()
    iparams = OrderedDict{String,Int64}()
    sparams = OrderedDict{String,String}()

    for (k,v) in kw
        ks = string(k)
        if isa(v, Integer)
            iparams[ks] = Int64(v)
        elseif isa(v, AbstractFloat)
            fparams[ks] = Float64(v)
        else # Let's try a string...
            sparams[ks] = string(v)
        end
    end

    return DaqConfig(devname, devtype, ip, model, sernum, tag, iparams, fparams, sparams)
           
            
end


"Retrieve integer configuration parameter"
iparam(dconf::DaqConfig, param) = dconf.iparams[param]
"Retrieve string configuration parameter"
sparam(dconf::DaqConfig, param) = dconf.sparams[param]
"Retrieve float configuration parameter"
fparam(dconf::DaqConfig, param) = dconf.fparams[param]

iparam!(dconf::DaqConfig, param, val::Integer) =
    dconf.iparams[string(param)] == Int64(val)
fparam!(dconf::DaqConfig, param, val::AbstractFloat) =
    dconf.fparams[string(param)] == Float64(val)
sparam!(dconf::DaqConfig, param, val::Union{AbstractString,Symbol,Char}) =
    dconf.sparams[string(param)] == string(val)

import Base.setindex!

setindex!(dconf::DaqConfig, val::Integer, param) = iparam!(dconf, string(param), val)
setindex!(dconf::DaqConfig, val::AbstractFLoat, param) = sparam!(dconf, Float64(param), val)
setindex!(dconf::DaqConfig, val::Union{AbstractString,Symbol,Char}, param) =
    sparam!(dconf, string(param), val)



