
# Testing points stuff

pts = DaqPoints(["X", "Y"], [1 101; 2 102; 3 103; 4 104])

@test parameters(pts) == ["X", "Y"]
@test numparams(pts) == 2
@test numpoints(pts) == 4

@test daqpoint(pts, 1) == [1,101]
@test daqpoint(pts, 2) == [2,102]
@test daqpoint(pts, 3) == [3,103]
@test daqpoint(pts, 4) == [4,104]

@test daqpoints(pts) == [1 101; 2 102; 3 103; 4 104]

pts = DaqPoints(X=1:4, Y=101:104)
@test parameters(pts) == ["X", "Y"]
@test numparams(pts) == 2
@test numpoints(pts) == 4

@test daqpoint(pts, 1) == [1,101]
@test daqpoint(pts, 2) == [2,102]
@test daqpoint(pts, 3) == [3,103]
@test daqpoint(pts, 4) == [4,104]

@test daqpoints(pts) == [1 101; 2 102; 3 103; 4 104]


xx = 1:3
yy = 101:102
zz = 1001:1002
pts = CartesianDaqPoints(x=xx, y=yy, z=zz)

@test numpoints(pts) == 3*2*2
@test numparams(pts) == 3
@test parameters(pts) == ["x", "y", "z"]

cnt = 1
for z in zz, y in yy, x in xx
    @test daqpoint(pts, cnt) == [x, y, z]
    global cnt += 1
end

@test daqpoints(pts) == [repeat(xx, length(yy)*length(zz))  repeat(yy, inner=length(xx), outer=length(zz))  repeat(zz, inner=length(xx)*length(yy))]


ptsx = DaqPoints(x=xx)
ptsy = DaqPoints(y=yy)
ptsz = DaqPoints(z=zz)

pts = DaqPointsProduct((ptsx, ptsy, ptsz))


@test numpoints(pts) == 3*2*2
@test numparams(pts) == 3
@test parameters(pts) == ["x", "y", "z"]
                 
cnt = 1
for z in zz, y in yy, x in xx
    @test daqpoint(pts, cnt) == [x, y, z]
    global cnt += 1
end

@test daqpoints(pts) == [repeat(xx, length(yy)*length(zz))  repeat(yy, inner=length(xx), outer=length(zz))  repeat(zz, inner=length(xx)*length(yy))]


pts = ptsx * ptsy * ptsz

@test numpoints(pts) == 3*2*2
@test numparams(pts) == 3
@test parameters(pts) == ["x", "y", "z"]
                 
cnt = 1
for z in zz, y in yy, x in xx
    @test daqpoint(pts, cnt) == [x, y, z]
    global cnt += 1
end

@test daqpoints(pts) == [repeat(xx, length(yy)*length(zz))  repeat(yy, inner=length(xx), outer=length(zz))  repeat(zz, inner=length(xx)*length(yy))]
