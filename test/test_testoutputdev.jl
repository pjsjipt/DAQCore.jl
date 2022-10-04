let

    dev = TestOutputDev("robot", ["x", "y", "z"])

    @test devposition(dev) == [0.0, 0.0, 0.0]

    moveto!(dev, [1.0, 2.0, 3.0])
    @test devposition(dev) == [1.0, 2.0, 3.0]

    @test numaxes(dev) == 3
    @test axesnames(dev) == ["x", "y", "z"]

    

end
