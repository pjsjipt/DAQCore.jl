using DAQCore
using Test

@testset "DAQCore.jl" begin

    include("test_circbuffer.jl")
    include("test_config.jl")
    include("test_channels.jl")
    include("test_points.jl")
    include("test_sampling.jl")
    include("test_measdata.jl")
    include("test_testoutputdev.jl")
end


