struct FlipX <: Aug
    p::Float64
end

function (a::FlipX)(xs)
    rand() > a.p && return xs
    [x[:, size(x, 2):-1:1] for x in xs]
end

struct FlipY <: Aug
    p::Float64
end

function (a::FlipY)(xs)
    rand() > a.p && return xs
    [x[size(x, 1):-1:1, :] for x in xs]
end

struct ToGray <: Aug
    p::Float64
end

function (a::ToGray)(xs)
    rand() > a.p && return xs
    [x .|> Gray .|> RGB for x in xs]
end

struct Downscale <: Aug
    p::Float64
    scale::Tuple{Float64, Float64}

    Downscale(p, scale::Tuple{Real, Real} = (0.25, 0.5)) =
        new(p, (minimum(scale), maximum(scale)))
end

function (a::Downscale)(xs)
    rand() > a.p && return xs
    res = eltype(xs)[]
    ratio = (rand() * (a.scale[2] - a.scale[1]) + a.scale[1])
    for x in xs
        original_size = x |> size
        push!(res, imresize(imresize(x; ratio), original_size))
    end
    res
end
