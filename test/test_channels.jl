# Testing the DaqChannels stuff


chs = DaqChannels("TestDev", "test", ["A", "B", "C", "D"], "101-104")

@test devname(chs) == "TestDev"
@test devtype(chs) == "test"
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

chs = DaqChannels("TestDev", "test", "E", 10)

@test numchannels(chs) == 10
@test daqchannels(chs) == ["E01", "E02", "E03", "E04", "E05",
                           "E06", "E07", "E08", "E09", "E10"]
