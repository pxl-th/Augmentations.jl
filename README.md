# Augmentations.jl

Simple library for image augmentations.
Its aim is to partially reproduce functionality
of the [Albumentations](https://albumentations.ai/) library.

## Example

```julia
augmentations = Sequential([
    OneOf(0.5, [CLAHE(;p=1, rblocks=2, cblocks=2), Equalize(1)]),
    OneOf(0.5, [ToGray(1), Downscale(1, (0.25, 0.75))]),
    FlipX(0.5),
    OneOf(0.5, [
        Blur(;p=1),
        GaussNoise(;p=1),
        RandomGamma(1, (0.5, 5)),
        RandomBrightness(1, 0.2),
    ]),
])

x = load("image.png")
y = augmentations([x])
save(raw"image-augmented.png", y[1])
```
