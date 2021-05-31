struct Blur <: Aug
    p::Float64
    σ_max::Float64
    sizes::NTuple{N, Int64} where N
end

function Blur(;
    p = 0.5, σ_max = 0.0, sizes::NTuple{N, Int64} where N = (3, 5, 7),
)
    Blur(p, σ_max, sizes)
end

function (a::Blur)(xs::AbstractVector{T})::AbstractVector{T} where T
    rand() > a.p && return xs

    ks::Int64 = rand(a.sizes)
    σ_max = a.σ_max ≈ 0.0 ? (0.3 * ((ks - 1.0) * 0.5 - 1.0) + 0.8) : a.σ_max
    σ = random(1e-6, σ_max)
    kernel = Kernel.gaussian((σ, σ), (ks, ks))

    [imfilter(x, kernel) for x in xs]
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
RandomGamma(p = 0.5, γ = 2) = RandomGamma(p, (1e-6, γ))

function (a::RandomGamma)(xs)
    rand() > a.p && return xs
    γ = random(a.γ...)
    [adjust_histogram(x, GammaCorrection(γ)) for x in xs]
end

struct GaussNoise <: Aug
    p::Float64
    σ_range::Tuple{Float64, Float64}
end
GaussNoise(;p = 0.5, σ_range::Tuple{Number, Number} = (0.03, 0.12)) =
    GaussNoise(p, σ_range)

function (a::GaussNoise)(xs)
    rand() > a.p && return xs
    res = eltype(xs)[]

    σ = random(a.σ_range...)
    for x in xs
        x = x |> channelview

        x = eltype(x).(clamp.(x .+ randn.() .* σ, 0.0, 1.0))
        x = colorview(RGB, x)
        push!(res, x)
    end
    res
end

struct RandomBrightness <: Aug
    p::Float64
    σ::Float64

    RandomBrightness(p = 0.5, σ = 0.2) = new(p, σ)
end

function (a::RandomBrightness)(xs)
    rand() > a.p && return xs
    res = eltype(xs)[]
    for x in xs
        x = x .|> HSV |> channelview
        @inbounds x[3, :, :] .= clamp.(
            @view(x[3, :, :]) .+ randn() * a.σ, 0.0, 1.0,
        )
        push!(res, colorview(HSV, x) .|> RGB)
    end
    res
end
