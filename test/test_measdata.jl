# Testing MeasData stuff

using Dates
let
    # Let's build get some 4 channels with units volts:
    nch = 4 # Number of channels
    chans = DaqChannels("test", "type", "E", nch, "V")

    # Let's build some data
    ns = 10 # Number of samples
    ee = range(0.4, length=nch, step=0.2)
    # Data with each channel having a different constant value.
    E = [ee[i] for i in 1:nch, k in 1:ns]

    
    # Sampling information
    tinit = now()
    sa = DaqSamplingRate(1.0, ns, tinit)

    X = MeasData("test", "type", sa, E, chans)

    @test devname(X) == "test"
    @test devtype(X) == "type"

    @test daqtime(X) == tinit
    @test numsamples(X) == ns
    @test numchannels(X) == nch
    @test daqchannels(X) == daqchannels(chans)
    
    for i in 1:nch
        @test X[i] == fill(ee[i], ns)
    end

    for (i,ch) in enumerate(daqchannels(X))
        @test X[ch] == fill(ee[i], ns)
    end

    @test measdata(X) == E
    @test X[] == E

    Eb = rand(nch, ns)
    Y = MeasData("test", "type", sa, Eb, chans)

    @test Y[2,3] == Eb[2,3]
    @test Y[3] == Eb[3,:]
    @test Y[1:3] == Eb[1:3,:]
    @test Y[3:4,6:10] == Eb[3:4,6:10]
    @test Y["E2",5] == Eb[2,5]
    @test Y["E3",8] == Eb[3,8]
    @test Y[["E1","E2"]] == Eb[1:2,:]
    @test Y[["E1","E2"],1] == Eb[1:2,1]
    @test Y[["E1","E2"],5:10] == Eb[1:2,5:10]
        

end
