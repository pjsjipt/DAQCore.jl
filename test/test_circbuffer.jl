# Testing circular buffer
buf = DAQCore.CircMatBuffer{Int}(4,5)

@test length(buf) == 0
@test DAQCore.capacity(buf) == 5
@test DAQCore.bufwidth(buf) == 4

@test eltype(buf) == Int

push!(buf, [1,2,3,4])
@test length(buf) == 1
@test buf[1] == [1,2,3,4]

push!(buf, [5,6,7,8])
@test length(buf) == 2

push!(buf, [9,10,11,12])
@test length(buf) == 3

push!(buf, [13,14,15,16])
@test length(buf) == 4

push!(buf, [17,18,19,20])
@test length(buf) == 5

@test buf[1] == [1,2,3,4]

push!(buf, [21,22,23,24])
@test length(buf) == 5
@test buf[1] != [1,2,3,4]
@test buf[1] == [5,6,7,8]
@test buf[end] == [21,22,23,24]

pushfirst!(buf, [25,26,27,28])
@test length(buf) == 5
@test buf[end] == [17,18,19,20]

lst = pop!(buf)
@test lst == [17,18,19,20]
@test length(buf) == 4

fst = popfirst!(buf)
@test fst == [25,26,27,28]
@test length(buf) == 3

nb = DAQCore.nextbuffer(buf)
@test length(buf) == 4
nb .= [29,30,31,32]
@test buf[end] == [29,30,31,32]

pop!(buf)
pop!(buf)
@test length(buf) == 2

DAQCore.pushfirst!(buf, [33,34,35,36])
@test length(buf) == 3
@test buf[begin] == [33,34,35,36]

append!(buf, [37 41; 38 42; 39 43; 40 44])
@test length(buf) == 5
@test buf[end] == [41,42,43,44]

append!(buf, [45 49; 46 50; 47 51; 48 52])
@test length(buf) == 5
@test buf[end] == [49,50,51,52]

@test DAQCore.isfull(buf)

pushfirst!(buf, [53,54,55,56])
@test first(buf) == [53,54,55,56]

a = zeros(Int, 4, 5)
for i in 1:5
    a[:,i] .= buf[i]
end

      
@test a == convert(Array, buf)

@test DAQCore.flatten(buf) == a

DAQCore.flatten!(buf)

for i in 1:length(buf)
    @test buf[i] == buf.buffer[:,i]
end


buf[1] = [1,2,3,4]

@test buf[1] == [1,2,3,4]

buf[end] = [4,5,6,7]
@test last(buf) == [4,5,6,7]

resize!(buf, 10)
@test DAQCore.capacity(buf) == 10

@test buf[1] == [1,2,3,4]
@test last(buf) == [4,5,6,7]
@test length(buf) == 5

b1 = copy(buf[1])
b2 = copy(buf[2])

resize!(buf, 2)

@test b1 == first(buf)
@test b2 == last(buf)
@test length(buf) == 2
@test DAQCore.capacity(buf) == 2  # Preserving the capacity

empty!(buf)
@test length(buf) == 0

resize!(buf, 2, 12)
@test DAQCore.bufwidth(buf) == 2
@test DAQCore.capacity(buf) == 12

resize!(buf, 3, 3)


@test DAQCore.capacity(buf) == 3
@test DAQCore.bufwidth(buf) == 3
@test length(buf) == 0





