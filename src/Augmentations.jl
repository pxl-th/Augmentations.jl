module Augmentations
export Blur, RandomGamma, RandomBrightness, GaussNoise, GammaCorrection
export CLAHE, Equalize, ToGray, Downscale, FlipX, FlipY
export OneOf, Sequential

using Images

abstract type Aug end

@inline random(minv, maxv) = rand() * (maxv - minv) + minv

include("normalization.jl")
include("transforms.jl")
include("noise.jl")

struct OneOf <: Aug
    p::Float32
    augmentations::Vector{A where A <: Aug}
end

function (a::OneOf)(xs::AbstractVector{T})::AbstractVector{T} where T
    rand() > a.p && return xs
    aid = rand(1:length(a.augmentations))
    xs |> a.augmentations[aid]
end

struct Sequential <: Aug
    augmentations::Vector{A where A <: Aug}
end

function (a::Sequential)(xs::AbstractVector{T})::AbstractVector{T} where T
    for aug in a.augmentations
        xs = xs |> aug
    end
    xs
end

# function main()
#     a = Sequential([
#         FlipX(0.5),
#         OneOf(0.5, [CLAHE(;p=1, rblocks=2, cblocks=2), Equalize(1)]),
#         OneOf(0.5, [ToGray(1), Downscale(1, (0.25, 0.75))]),
#         OneOf(0.5, [
#             Blur(;p=1),
#             GaussNoise(;p=1, σ_range=(0.03, 0.08)),
#             RandomGamma(1, (0.5, 5)),
#             RandomBrightness(1, 0.2),
#         ]),
#     ])

#     x = load(raw"1.png")
#     y = a([x])[1]
#     save(raw"./1a.png", y)
# end
# main()

end
