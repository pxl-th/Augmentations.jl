module Augmentations

using Images

abstract type Aug end

@inline random(minv, maxv) = rand() * (maxv - minv) + minv

struct Blur <: Aug
    p::Float64
    σ_max::Float64
    sizes::NTuple{N, Int64} where N
end

function Blur(;
    p::Number, σ_max::Number = 0, sizes::NTuple{N, Int64} where N = (3, 5, 7),
)
    Blur(p, σ_max, sizes)
end

function (a::Blur)(xs)
    rand() > a.p && return xs

    ks = rand(a.sizes)
    σ = random(1e-6, a.σ_max ≈ 0 ? (0.3 * ((ks - 1) * 0.5 - 1) + 0.8) : a.σ_max)
    kernel = Kernel.gaussian((σ, σ), (ks, ks))

    [imfilter(x, kernel) for x in xs]
end

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

struct CLAHE <: Aug
    p::Float64
end

function (a::CLAHE)(xs)
    rand() > a.p && return xs
    eq = AdaptiveEqualization()
    [adjust_histogram(x, eq) for x in xs]
end

struct ToGray <: Aug
    p::Float64
end

function (a::ToGray)(xs)
    rand() > a.p && return xs
    [x .|> Gray .|> RGB for x in xs]
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

function (a::RandomGamma)(xs)
    rand() > a.p && return xs
    γ = random(a.γ...)
    [adjust_histogram(x, GammaCorrection(γ)) for x in xs]
end

struct GaussNoise <: Aug
    p::Float64
    σ_range::Tuple{Float64, Float64}
end
GaussNoise(;p::Number, σ_range::Tuple{Number, Number} = (0.03, 0.12)) =
    GaussNoise(p, σ_range)

function (a::GaussNoise)(xs)
    rand() > a.p && return xs
    res = eltype(xs)[]

    σ = random(a.σ_range...)
    for x in xs
        x = x |> channelview

        x = eltype(x).(clamp.(x .+ randn.() .* σ, 0, 1))
        x = colorview(RGB, x)
        push!(res, x)
    end
    res
end

struct Downscale <: Aug
    p::Float64
    scale::Tuple{Float64, Float64}

    Downscale(p::Real, scale::Tuple{Real, Real} = (0.25, 0.25)) =
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

struct Equalize <: Aug
    p::Float64
end

function (a::Equalize)(xs)
    rand() > a.p && return xs
    eq = Equalization()
    [adjust_histogram(x, eq) for x in xs]
end

struct RandomBrightness <: Aug
    p::Float64
    σ::Float64
end

function (a::RandomBrightness)(xs)
    rand() > a.p && return xs
    res = eltype(xs)[]
    for x in xs
        x = x .|> HSV |> channelview
        x[3, :, :] .= clamp.(x[3, :, :] .+ randn() * a.σ, 0, 1)
        push!(res, colorview(HSV, x) .|> RGB)
    end
    res
end

struct OneOf <: Aug
    p::Float32
    augmentations::Vector{A where A <: Aug}
end

function (a::OneOf)(xs)
    rand() > a.p && return xs
    aid = rand(1:length(a.augmentations))
    xs |> a.augmentations[aid]
end

struct Sequential <: Aug
    augmentations::Vector{A where A <: Aug}
end

function (a::Sequential)(xs)
    for aug in a.augmentations
        xs = xs |> aug
    end
    xs
end

function main()
    x = load(raw"./spaceshuttle.png")
    # a = Sequential([
    #     OneOf(1, [CLAHE(1), Equalize(1)]),
    #     OneOf(1, [ToGray(1), Downscale(1, (0.25, 0.75))]),
    #     Blur(1, 3),
    #     FlipX(1),
    #     OneOf(1, [
    #         GaussNoise(1, 0.1),
    #         RandomGamma(1, (0.5, 5)),
    #         RandomBrightness(1, 0.2),
    #     ]),
    # ])
    a = RandomGamma(1, (0.5, 5))
    y = a([x])[1]
    @show size(y), typeof(y)
    save(raw"./spaceshuttle-w.png", y)
end
main()

end
