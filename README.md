# DAQCore

This [Julia](https://julialang.org) package implements basic infrastructure for doing data acquisition and managing experiments in Julia


## Related software

`DAQCore.jl` implements the basic infrastructure. Othe packages implement interfaces with specific equipments and instruments.

 * [Scanivalve](https://github.com/pjsjipt/Scanivalve.jl) interfaces with Scanivalve pressure scanners, specifically the DSA3217 series pressure scanners
 * [Pressure Systems Initium](https://github.com/pjsjipt/DTCInitium.jl) interfaces with the Initium ESP control and data system.
 * [NIDAQmx](https://github.com/pjsjipt/DAQnidaqmx.jl) implements a interface to NIDAQmx boards. Very minimal interface.
 * [DAQHDF5](https://github.com/pjsjipt/DAQHDF5.jl) that handles saving data acquisition data and configuration.
 
 

[![Build Status](https://github.com/pjsjipt/DAQCore.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/pjsjipt/DAQCore.jl/actions/workflows/CI.yml?query=branch%3Amain)
