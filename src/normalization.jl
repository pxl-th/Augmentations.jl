struct CLAHE <: Aug
    p::Float64
    eq::AdaptiveEqualization
end
CLAHE(;p::Number, kwargs...) = CLAHE(p, AdaptiveEqualization(;kwargs...))

function (a::CLAHE)(xs)
    rand() > a.p && return xs
    [adjust_histogram(x, a.eq) for x in xs]
end

struct Equalize <: Aug
    p::Float64
end

function (a::Equalize)(xs)
    rand() > a.p && return xs
    eq = Equalization()
    [adjust_histogram(x, eq) for x in xs]
end
