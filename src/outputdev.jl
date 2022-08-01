# Generic interface for output devices


"""
`numaxes(dev)`

Return the number of degrees of freedom of the actuator.
"""
function numaxes end


"""
`axesnames(dev)`

Return the names of each individual axis on an output device.
"""
function axesnames end

"""
`moveto(move, x)`

Move to an arbitrary point. The point is specified by vector `x`. 

"""
function moveto end

function devposition end

"""
`stopoutputdev(dev)`

Stop all motion of the robot. 
"""
function stopoutputdev end


"""
`waituntildone(dev)`

Only return when all output is done.
"""
function waituntildone end



