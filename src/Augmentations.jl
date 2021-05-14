module Augmentations

using Images

abstract type Aug end

struct Blur <: Aug
    p::Float64
    kernel::Int64
end

function (a::Blur)(xs)
    rand() > a.p && return xs
    [imfilter(x, Kernel.gaussian(a.kernel)) for x in xs]
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
    γ = rand() * (a.γ[2] - a.γ[1]) + a.γ[1]
    [adjust_histogram(x, GammaCorrection(γ)) for x in xs]
end

struct GaussNoise <: Aug
    p::Float64
    σ::Float64
end

function (a::GaussNoise)(xs)
    rand() > a.p && return xs
    res = eltype(xs)[]

    for x in xs
        x = x |> channelview
        x = eltype(x).(clamp.(x .+ randn.() .* a.σ, 0, 1))
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

# function main()
#     x = load(raw"C:\Users\tonys\Downloads\spaceshuttle.png")
#     a = Sequential([
#         OneOf(1, [CLAHE(1), Equalize(1)]),
#         OneOf(1, [ToGray(1), Downscale(1, (0.25, 0.75))]),
#         Blur(1, 3),
#         FlipX(1),
#         OneOf(1, [
#             GaussNoise(1, 0.1),
#             RandomGamma(1, (0.5, 5)),
#             RandomBrightness(1, 0.2),
#         ]),
#     ])
#     y, y1 = a([x, x])
#     save(raw"C:\Users\tonys\Downloads\spaceshuttle-w.png", y)
#     save(raw"C:\Users\tonys\Downloads\spaceshuttle-w1.png", y1)
# end
# main()

end
