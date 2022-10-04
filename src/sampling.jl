# Sampling rates and times stuff

using Dates

export AbstractDaqSampling, DaqSamplingRate, DaqSamplingTimes
export daqtime, samplingrate, samplingtimes, samplinghours
export numsamples, samplingperiod



"""
`DaqSamplingRate(rate, nsamples, time)`

Data acquisition timing when the sampling rate is fixed.

If instead of a fixed sampling rate, specific sampling times
is required, use [`DaqSamplingTimes`](@ref). If neither of these types
is sufficient, just implement a new [`AbstractDaqSampling`](@ref) struct.

The following methods are available:
 * [`daqtime`](@ref) to retrieve initial data acquisition time
 * [`samplingrate`](@ref) to get the sampling rate in Hz
 * [`samplingtimes`](@ref) to get the sampling times in seconds of each sample from the beginning
 * [`samplinghours`](@ref) to get a [`Dates.DateTime`](@ref) object of each sample.
 * [`Base.getindex`](@ref) to retrieve a specific sampling time
 * [`numsamples`](@ref) or [`Base.length`](@ref) to get the total number of samples.

## Arguments
 * `rate` Sampling rate in Hz
 * `nsamples` Number of samples
 * `time` `DateTime` object when the data acquisition started

## Example

```julia-repl
julia> s = DaqSamplingRate(1.0, 3, now())
DaqSamplingRate(1.0, 3, DateTime("2022-10-04T10:14:36.072"))

julia> daqtime(s)
2022-10-04T10:14:36.072

julia> samplingrate(s)
1.0

julia> samplingtimes(s)
0.0:1.0:2.0

julia> samplinghours(s)
3-element Vector{DateTime}:
 2022-10-04T10:14:36.072
 2022-10-04T10:14:37.072
 2022-10-04T10:14:38.072
```
"""
struct DaqSamplingRate <: AbstractDaqSampling
    "Sampling rate in Hz"
    rate::Float64
    "Number of samples acquired"
    nsamples::Int64
    "Time when the sampling occurred"
    time::DateTime
    DaqSamplingRate(rate,nsamples=1,time=now()) = new(rate,nsamples,time)
end

"Return Sampling time"
daqtime(r::DaqSamplingRate) = r.time

"Return the number of samples acquired"
numsamples(r::DaqSamplingRate) = r.nsamples

Base.length(r::DaqSamplingRate) = r.nsamples

Base.getindex(r::DaqSamplingRate, i) = (i .- 1) ./ r.rate

"Return the sampling rate"
samplingrate(r::DaqSamplingRate) = r.rate

"Return the sampling times in seconds from begining"
samplingtimes(r::DaqSamplingRate) = range(0.0, length=r.nsamples,
                                          step=1/r.rate)
"Return the hour when each sampling occurred"
function samplinghours(r::DaqSamplingRate)
    t1 = r.time
    dt = Nanosecond(round(Int,1e9/r.rate)) # Nanosecond for accuracy...
    return t1 .+ (0:r.nsamples-1) * dt   #range(t1, length=r.nsamples, step=dt)
end

samplingperiod(r::DaqSamplingRate) = (r.nsamples-1)/r.rate

import Dates: AbstractDateTime


"""
`DaqSamplingTimes(t)`

Sampling times when each sample is timed.

Each sampling time should be an `AbstractDateTime`, usually
`DateTime` itself. Any kind of abstract vector can be used.

If instead of a sampling times, specific fixed sampling rate is required, 
use [`DaqSamplingRate`](@ref). If neither of these types
is sufficient, just implement a new [`AbstractDaqSampling`](@ref) struct.

The following methods are available:
 * [`daqtime`](@ref) to retrieve initial data acquisition time
 * [`samplingrate`](@ref) to get the sampling rate in Hz
 * [`samplingtimes`](@ref) to get the sampling times in seconds of each sample from the beginning
 * [`samplinghours`](@ref) to get a [`Dates.DateTime`](@ref) object of each sample.
 * [`Base.getindex`](@ref) to retrieve a specific sampling time
 * [`numsamples`](@ref) or [`Base.length`](@ref) to get the total number of samples.

## Example

```julia-repl
julia> s = DaqSamplingTimes(t)
DaqSamplingTimes{DateTime, Vector{DateTime}}([DateTime("2022-10-04T10:17:38.293"), DateTime("2022-10-04T10:17:39.293"), DateTime("2022-10-04T10:17:40.293"), DateTime("2022-10-04T10:17:41.293")])

julia> samplingrate(s)
1.0

julia> samplingtimes(s)
4-element Vector{Float64}:
 0.0
 1.0
 2.0
 3.0

julia> samplinghours(s)
4-element Vector{DateTime}:
 2022-10-04T10:17:38.293
 2022-10-04T10:17:39.293
 2022-10-04T10:17:40.293
 2022-10-04T10:17:41.293

```
"""
struct DaqSamplingTimes{T<:AbstractDateTime,V<:AbstractVector{T}} <: AbstractDaqSampling
    "DateTime of each sample read"
    t::V
end

daqtime(r::DaqSamplingTimes) = r.t[begin]
numsamples(r::DaqSamplingTimes) = length(r.t)

Base.length(r::DaqSamplingTimes) = length(r.t)
Base.getindex(r::DaqSamplingTimes, i) = r.t[i]

function samplingrate(r::DaqSamplingTimes)
    # The best we can do is an average sampling rate!
    dt = r.t[end] - r.t[begin] # Sampling interval

    return (numsamples(r)-1) / (Nanosecond(dt).value / 1e9)
end

samplinghours(r::DaqSamplingTimes) = r.t

function samplingtimes(r::DaqSamplingTimes)
    t1 = r.t[begin]
    return [Nanosecond(t-t1).value/1e9 for t in r.t]
end

    

samplingperiod(r::DaqSamplingTimes) = Nanosecond(r.t[end]-r.t[begin]) / 1e9

# This might depend on accuracy
DaqSamplingTimes(r::DaqSamplingRate) = DaqSamplingTimes(samplinghours(r))

     
#"Convert a DateTime object to ms"
#time2ms(t::DateTime) = t.instant.periods.value
#"Convert a time in ms to DateTimeObject"
#ms2time(ms::Int64) = DateTime(Dates.UTInstant{Millisecond}(Millisecond(ms)))
   

