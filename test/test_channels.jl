# Testing the DaqChannels stuff


let 
    chs = DaqChannels(["A", "B", "C", "D"], "101-104")

    @test numchannels(chs) == 4
    @test daqchannels(chs) == ["A", "B", "C", "D"]
    
    @test chs["A"] == 1
    @test chs["B"] == 2
    @test chs["C"] == 3
    @test chs["D"] == 4
    
    @test chs[1] == "A"
    @test chs[2] == "B"
    @test chs[3] == "C"
    @test chs[4] == "D"
    
    @test physchans(chs) == "101-104"

    chs[1] = "AAA"

    @test daqchannels(chs)[1] == "AAA"

    chs1 = chanslice(chs, 2:3)
    @test numchannels(chs1) == 2
    @test daqchannels(chs1) == daqchannels(chs)[2:3]

    chs1 = chanslice(chs, ["B", "C"])
    @test numchannels(chs1) == 2
    @test daqchannels(chs1) == daqchannels(chs)[2:3]
    
    
    chs = DaqChannels("E", 10)

    @test numchannels(chs) == 10
    @test daqchannels(chs) == ["E01", "E02", "E03", "E04", "E05",
                               "E06", "E07", "E08", "E09", "E10"]

    chs[4] = "chan04"

    @test chs["chan04"] == 4


    @test numchannels(5) == 5
    @test daqchannels(3) == ["1", "2", "3"]
    @test daqchan(5, 3) == "3"
    @test chanindex(5, "3") == 3
    @test chanslice(5, 2:3) == [2,3]
    

    @test numchannels([5,7,9,11]) == 4
    @test daqchannels([5,7,9,11]) == ["5", "7", "9", "11"]
    @test daqchan([5,7,9,11], 2) == "7"
    @test chanindex([5,7,9,11], 9) == 3
    @test chanindex([5,7,9,11], "9") == 3
    @test chanslice([5,7,9,11], 2:3) == [7,9]
    @test chanslice([5,7,9,11], ["7", "9"]) == [7,9]

    @test numchannels(["E1", "E2", "E3"]) == 3
    @test daqchannels(["E1", "E2", "E3"]) == ["E1", "E2", "E3"]
    @test daqchan(["E1", "E2", "E3"], 2) == "E2"
    @test chanindex(["E1", "E2", "E3"], "E2") == 2
    @test chanslice(["E1", "E2", "E3"], 2:3) == ["E2", "E3"]
    @test chanslice(["E1", "E2", "E3"], ["E3"]) == ["E3"]
    @test chanslice(["E1", "E2", "E3"], ["E2", "E3"]) == ["E2"," E3"]
    
end
