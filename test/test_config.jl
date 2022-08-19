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

    iparam!(c, "X"=>1, "Y"=>2)
    @test iparam(c, "X") == 1
    @test iparam(c, "Y") == 2

    fparam!(c, "X"=>1.0, "Y"=>2.0)
    @test iparam(c, "X") == 1.0
    @test iparam(c, "Y") == 2.0

    sparam!(c, "X"=>"one", "Y"=>"two")
    @test sparam(c, "X") == "one"
    @test sparam(c, "Y") == "two"
    
    oparam!(c, "X"=>1//2, "Y"=>2//3)
    @test oparam(c, "X") == 1//2
    @test oparam(c, "Y") == 2//3

    oparam!(c, "MAT"=>[1 2; 3 4])
    c1 = copy(c)
    @test devname(c) == devname(c1)
    @test devtype(c) == devtype(c1)
    @test daqdevip(c) == daqdevip(c1)
    @test daqdevport(c) == daqdevport(c1)
    @test daqdevmodel(c) == daqdevmodel(c1)
    @test daqdevserial(c) == daqdevserial(c1)
    @test daqdevtag(c) == daqdevtag(c1)

    for (k,v) in c.iparams
        @test iparam(c1, k) == v
    end

    for (k,v) in c.fparams
        @test fparam(c1, k) == v
    end

    for (k,v) in c.sparams
        @test sparam(c1, k) == v
    end

    for (k,v) in c.oparams
        @test oparam(c1, k) == v
    end

    # Testing the deepcopy
    oparam(c1, "MAT")[1,1] = 999
    @test oparam(c, "MAT")[1,1] == 1
    
    
    
    # Let's test the methods for AbstractDevices

    dev = TestDaq("test")
    
    iparam!(dev, "X", 1)
    @test iparam(dev, "X") == 1
    iparam!(dev, "Y"=>2)
    @test iparam(dev, "Y") == 2
    iparam!(dev, "Z"=>3, "W"=>4)
    @test iparam(dev, "Z") == 3
    @test iparam(dev, "W") == 4



    fparam!(dev, "X", 1.0)
    @test fparam(dev, "X") == 1.0
    fparam!(dev, "Y"=>2.0)
    @test fparam(dev, "Y") == 2.0
    fparam!(dev, "Z"=>3.0, "W"=>4.0)
    @test fparam(dev, "Z") == 3.0
    @test fparam(dev, "W") == 4.0

    sparam!(dev, "X", "one")
    @test sparam(dev, "X") == "one"
    sparam!(dev, "Y"=>"two")
    @test sparam(dev, "Y") == "two"
    sparam!(dev, "Z"=>"three", "W"=>"four")
    @test sparam(dev, "Z") == "three"
    @test sparam(dev, "W") == "four"

    oparam!(dev, "X", "one")
    @test oparam(dev, "X") == "one"
    oparam!(dev, "Y"=>2.0)
    @test oparam(dev, "Y") == 2.0
    oparam!(dev, "Z"=>1//3, "W"=>[1 2; 3 4])
    @test oparam(dev, "Z") == 1//3
    @test oparam(dev, "W") == [1 2; 3 4]


    

end
