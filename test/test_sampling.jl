# Testing sampling stuff


using Dates

let
    tinit = now()

    r = DaqSamplingRate(10.0, 10, tinit)
    
    @test daqtime(r) == tinit
    @test numsamples(r) == 10
    @test samplingrate(r) == 10.0
    
    tt1 = samplingtimes(r)
    @test length(tt1) == 10
    @test tt1[1] == 0
    @test tt1[2] == 1/samplingrate(r)
    
    tt2 = samplinghours(r)
    @test tt2[1] == tinit
    @test length(tt2) == 10
    @test Millisecond(tt2[2]-tt2[1]) == Millisecond(100)
    @test Millisecond(tt2[end]-tt2[begin]) == 9*Millisecond(100)
    
    @test samplingperiod(r) == 9 / 10.0
    
    
    ra = DaqSamplingTimes(r)
    
    @test numsamples(ra) == 10
    @test samplingrate(ra) == 10.0
    
    tt3 = samplingtimes(ra)
    @test length(tt3) == 10
    @test tt3[1] == 0
    @test tt3[2] == 1/samplingrate(r)
    
    tt4 = collect(ra.t)
    
    rb = DaqSamplingTimes(tt4)
    
    @test samplingrate(rb) == 10.0
    @test numsamples(rb) == 10
    @test samplinghours(rb)[1] == tinit
    @test samplinghours(rb) == samplinghours(ra)
    @test samplingtimes(rb) == samplingtimes(ra) == samplingtimes(r)

end
