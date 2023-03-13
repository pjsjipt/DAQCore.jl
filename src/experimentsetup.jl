
# Setup experimental points

export ExperimentSetup, lastpoint, incpoint!, setpoint!, movenext!
export finishedpoints, inputdevice, outputdevice

"""
`ExperimentSetup(idev, pts, odev)`

Creates a structure that handles experiment setup.
Experiment setup in this context is the set of input devices,
output devices and points where the output devices should be
positioned to measure the input devices.

The output device (`odev`) is used to set the configuration corresponding to each
point (`points`) where the input device (`idev`) will measure the data.

This is done sequentially from the first point until the test ends.

The point that was done is specified by the field `lastpoint`. Usually when an
experiment begins, there was no previous point and `lastpoint=0`. Once the
experiemnt begins, field `started` is set to `true`. The output device (`odev`)
'moves' the system to the first point using method [`movenext!`](@ref).
While there are points to be measured, the method [`movenext!`](@ref) returns `true`.
Once the last point has been measured, [`movenext!`](@ref) returns `false` and
the experiment is considered over.

To 'move' the system to a new point (defined in field `points`), [`movenext!`](@ref)
acts on the output device `odev`. Each parameter in `points` corresponds to an
axis in `odev`. If `points` and `odev` were created with different names, a map can
be specified.

`ExperimentSetup` does not do any coordinate change. This should be defined outside,
preferably by creating a new output device that handles the transformation.

If the output device is a [`OutputDevSet`](@ref) and the points
[`DaqPointsProduct`](@ref), the method [`movenext`](@ref) will move each
output device independently and will check if the points associated with
the axes of each individual output device that makes up the `OutputDevSet`
actually changed.

## Examples

```julia-repl
ulia> idev = TestDaq("Device1"); daqaddinput(idev, ["E1", "E2"]);

julia> odev = TestOutputDev("fan", ["RPM"]);

julia> pts = DaqPoints(vel=200:50:300);

julia> setup = ExperimentSetup(idev, pts, odev, Dict("RPM"=>"vel"));

julia> while movenext!(setup)
           println(daqpoint(setup.points, lastpoint(setup)))
       end
[200.0]
[250.0]
[300.0]
```
"""
mutable struct ExperimentSetup{ODev<:AbstractDaqPlan,IDev<:AbstractInputDev,Filter} <: AbstractExperimentSetup
    "Data Input Devices"
    idev::IDev
    "Experiment Plan"
    odev::ODev
    "Data Filtering and processing"
    filt::Filter
end







function ExperimentSetup(idev::AbstractInputDev, pts::AbstractDaqPoints,
                         odev::AbstractOutputDev)
    
    return ExperimentSetup(idev, DaqPlan(dev, pts), 1)
end




"""
`finishedpoints(pts)`

Check if the experiment is done! For `ExperimentSetup`, we should just check
whether the index of the lastpoint corresponds to the number of points.

It is possible, in some applications, to have a dynamic behavior so that a priori
there is no set number of points. In cases like this, a new method should be created
that check if the problem is done.

"""
finishedpoints(pts::ExperimentSetup) = finishedpoints(pts.odev)

"""
`lastpoint(pts)`

Return the index of the last point tested. Point `0` means that no points were tested.
"""
lastpoint(pts::AbstractExperimentSetup) = lastpoint(dev.odev)

"""
`incpoint!(pts)`

Increment point counter.
"""
incpoint!(pts::AbstractExperimentSetup) = incpoint!(dev.odev)

"""
`setpoint!(pts, i)`

Set point counter so that the next point tested is the `i-th` point.
Remember that the first point is 1 and therefore to restart things,
the last point should be 0. 

"""
setpoint!(pts::AbstractExperimentSetup, i) = setpoint!(pts.odev, i)

movenext!(pts::ExperimentSetup) = movenext!(pts.odev)

daqpoints(pts::ExperimentSetup) = daqpoints(pts.points)
daqpoint(pts::ExperimentSetup, i) = daqpoint(pts.points, i)
parameters(pts::ExperimentSetup) = parameters(pts.points)
numparams(pts::ExperimentSetup) = numparams(pts.points)
numpoints(pts::ExperimentSetup) = numpoints(pts.points)

axesnames(pts::ExperimentSetup) = axesnames(pts.odev)
numaxes(pts::ExperimentSetup) = numaxes(pts.odev)

"Return the input device of the `ExperimentSetup`"
inputdevice(pts::ExperimentSetup) = pts.idev
"Return the output device of the `ExperimentSetup`"
outputdevice(pts::ExperimentSetup) = pts.odev


