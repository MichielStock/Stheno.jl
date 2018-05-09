using IterTools, FillArrays

import Base: length, size
import Distances: pairwise

abstract type MeanFunction end
abstract type CrossKernel end
abstract type Kernel <: CrossKernel end

@inline isstationary(::Type{<:CrossKernel}) = false
@inline isstationary(x::CrossKernel) = isstationary(typeof(x))

# Number of observations.
@inline nobs(x::AbstractVector) = length(x)
@inline nobs(X::AbstractMatrix) = size(X, 2)

# Dimensionality of observations.
@inline ndims(x::AbstractVector) = 1
@inline ndims(X::AbstractMatrix) = size(X, 1)

# Return observation in appropriate way depending upon container type.
@inline getobs(x::AbstractVector, n) = x[n]
@inline getobs(X::AbstractMatrix, n) = X[:, n]

# Fallback implementations for `unary_obswise`.
@inline unary_obswise(f, X::AbstractVecOrMat) = unary_obswise_fallback(f, X)

unary_obswise_fallback(f, X::AVM) = map(n->f(getobs(X, n)), 1:nobs(X))

# Fallback implementations for `binary_obswise`.
@inline binary_obswise(f, X::AbstractVecOrMat) =
    isstationary(f) ?
        Fill(f(getobs(X, 1), getobs(X, 1)), nobs(X)) :
        binary_obswise(f, X, X)
@inline binary_obswise(f, X::AVM, X′::AVM) = binary_obswise_fallback(f, X, X′)

binary_obswise_fallback(f, X::AVM, X′::AVM) =
    map(n->f(getobs(X, n), getobs(X′, n)), 1:nobs(X))

# Fallback implementation for `pairwise`.
@inline pairwise(f, X::AbstractVecOrMat) = pairwise(f, X, X)
@inline pairwise(f::Kernel, X::AbstractVecOrMat) = LazyPDMat(pairwise(f, X, X))
@inline pairwise(f, X::AVM, X′::AVM) = pairwise_fallback(f, X, X′)

pairwise_fallback(f, X::AVM, X′::AVM) =
    [f(getobs(X, p), getobs(X′, q)) for p in 1:nobs(X), q in 1:nobs(X′)]

# COMMITING TYPE PIRACY!
pairwise(f::PreMetric, x::AbstractVector) = pairwise(f, RowVector(x))
pairwise(f::PreMetric, x::AV, x′::AV) = pairwise(f, RowVector(x), RowVector(x′))