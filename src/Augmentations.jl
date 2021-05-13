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

struct RandomGamma <: Aug
    p::Float64
    γ::Tuple{Float64, Float64}

    function RandomGamma(p::Number, γ::Tuple{Number, Number})
        !(0 ≤ p ≤ 1) && throw("p must be in [0, 1] range: $p.")
        γ[1] ≈ γ[2] && throw("γ min/max parameters must be different: $γ.")
        new(p, (minimum(γ), maximum(γ)))
    end
end
RandomGamma(p::Number, γ::Number) = RandomGamma(p, (1e-6, γ))

function (a::RandomGamma)(x)
    rand() > a.p && return x
    γ = rand() * (a.γ[2] - a.γ[1]) + a.γ[1]
    @info γ
    adjust_histogram(x, GammaCorrection(γ))
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
    random brightness, contrast, hsv
    """
    x = load(raw"C:\Users\tonys\Downloads\pug.png")
    # a = Sequential([
    #     CLAHE(1),
    #     OneOf(1, [ToGray(1), Blur(1, 3)]),
    #     FlipX(1),
    # ])
    a = RandomGamma(1, (0.5, 5))
    y = a(x)
    save(raw"C:\Users\tonys\Downloads\pug-flipped.png", y)
end
main()

end
