module Augmentations

using Images

abstract type Aug end

struct Blur <: Aug
    p::Float64
    kernel::Int64
end

function (a::Blur)(x)
    rand() > a.p && return x
    imfilter(x, Kernel.gaussian(a.kernel))
end

struct FlipX <: Aug
    p::Float64
end

function (a::FlipX)(x)
    rand() > a.p && return x
    x[:, size(x, 2):-1:1]
end

struct CLAHE <: Aug
    p::Float64
end

function (a::CLAHE)(x)
    rand() > a.p && return x
    adjust_histogram(x, AdaptiveEqualization())
end

struct ToGray <: Aug
    p::Float64
end

function (a::ToGray)(x::AbstractArray{T}) where T <: Color
    rand() > a.p && return x
    x .|> Gray .|> T
end

struct OneOf <: Aug
    p::Float32
    augmentations::Vector{A where A <: Aug}
end

function (a::OneOf)(x)
    rand() > a.p && return x
    aid = rand(1:length(a.augmentations))
    x |> a.augmentations[aid]
end

struct Sequential <: Aug
    augmentations::Vector{A where A <: Aug}
end

function (a::Sequential)(x)
    for aug in a.augmentations
        x = x |> aug
    end
    x
end

function main()
    """
    TODO
    random noise
    random brightness, contrast, gamma, hsv
    """

    x = load(raw"C:\Users\tonys\Downloads\pug.png")
    a = Sequential([
        CLAHE(1),
        OneOf(1, [ToGray(1), Blur(1, 3)]),
        FlipX(1),
    ])
    y = a(x)
    save(raw"C:\Users\tonys\Downloads\pug-flipped.png", y)
end
main()

end
