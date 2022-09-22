import DataStructures: OrderedDict

let
    dev = TestDaq("amb")
    daqaddinput(dev, ["T", "Tbs", "Tbu", "Pa"], amp=0.0, freq=10.0, offset=1.0)
    @test numchannels(dev) == 4
    @test daqchannels(dev) == ["T", "Tbs", "Tbu", "Pa"]
    @test devname(dev) == "amb"
    pts_a = DaqCartesianPoints(x=[-100,0,100], z=[100,200,300,400])
    pts_b = DaqPoints(ang=0:15.0:345.0)
    pts = DaqPointsProduct(pts_a, pts_b)
    @test numparams(pts) == 3
    @test numpoints(pts) == 3*4*24
    @test parameters(pts) == ["x", "z", "ang"]
    
    odev_a = TestOutputDev("turntable", ["θ"])
    odev_b = TestOutputDev("robot", ["A", "B"])
    odev = OutputDevSet("wind_tunnel", (odev_a, odev_b))

    axmap = OrderedDict("A"=>"z", "θ"=>"ang", "B"=>"x")

    exp_setup = ExperimentSetup(dev, pts, odev, axmap)
    @test exp_setup.idx == [3,2,1]
    @test exp_setup.axmap == axmap
    @test exp_setup.parmap == Dict("z"=>"A", "x"=>"B", "ang"=>"θ")
    @test axesnames(exp_setup) == ["θ", "A", "B"]
    @test daqpoint(exp_setup, 13) == [-100.0, 100.0, 15.0]
    @test daqpoint(exp_setup, 13)[exp_setup.idx] == [15.0, 100.0, -100.0]
end
