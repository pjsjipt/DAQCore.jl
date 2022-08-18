# Testing the DaqConfig stuff

let
    c = DaqConfig("devname", "devtype"; ip="localhost", port=22, model="model", sn="1234",
                  tag="TAG", a=0.0, b=1, c="PARAM", d=[1 2; 3 4])
    
    @test devname(c) == "devname"
    @test devtype(c) == "devtype"
    
    @test daqdevip(c) == "localhost"
    @test daqdevport(c) == 22
    @test daqdevmodel(c) == "model"
    @test daqdevserial(c) == "1234"
    @test daqdevtag(c) == "TAG"
    
    
    @test iparam(c, "b") == 1
    @test fparam(c, "a") == 0.0
    @test sparam(c, "c") == "PARAM"
    @test oparam(c, "d") == [1 2; 3 4]
    
    
    iparam!(c, "b", 2)
    @test iparam(c, "b") == 2
    iparam!(c, "bb", 3)
    @test iparam(c, "bb") == 3
    
    fparam!(c, "a", 1.1)
    @test fparam(c, "a") == 1.1
    fparam!(c, "aa", 2.2)
    @test fparam(c, "aa") == 2.2
    
    
    sparam!(c, "c", "one")
    @test sparam(c, "c") == "one"
    sparam!(c, "cc", "two")
    @test sparam(c, "cc") == "two"
    
    oparam!(c, "d", 1.1)
    @test oparam(c, "d") == 1.1
    M = rand(2,3,4)
    oparam!(c, "dd", M)
    @test oparam(c, "dd") == M
    
    
    c["a"] = 3.14
    @test fparam(c, "a") == 3.14
    
    c["b"] = 123
    @test iparam(c, "b") == 123
    
    c["c"] = "THREE"
    @test sparam(c, "c") == "THREE"
    
    c["d"] = 2*M
    @test oparam(c, "d") == 2*M


end
