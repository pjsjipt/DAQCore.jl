using DAQCore
using Test

@testset "DAQCore.jl" begin

    include("test_circbuffer.jl")
    include("test_config.jl")

end
