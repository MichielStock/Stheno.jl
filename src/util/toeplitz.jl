using ToeplitzMatrices
import LinearAlgebra: Symmetric, *, mul!

import Base: transpose, adjoint, copy
import Base.Broadcast: broadcasted, materialize
import ToeplitzMatrices: Toeplitz, AbstractToeplitz

function copy(T::Toeplitz)
    return Toeplitz(copy(T.vc), copy(T.vr), copy(T.vcvr_dft), copy(T.tmp), T.dft)
end
function copy(T::SymmetricToeplitz)
    return SymmetricToeplitz(copy(T.vc), copy(T.vcvr_dft), copy(T.tmp), T.dft)
end

"""
    chol!(L::AbstractMatrix, T::SymmetricToeplitz)

Implementation adapted from "On the stability of the Bareiss and related
Toeplitz factorization algorithms", Bojanczyk et al, 1993. LOWER TRIANGULAR!
"""
function chol!(L::AbstractMatrix, T::SymmetricToeplitz)

    # Initialize.
    L[:, 1] .= T.vc ./ sqrt(T.vc[1])
    v = copy(L[:, 1])
    N = size(T, 1)

    # Iterate.
    @inbounds for n in 1:N-1
        sinθn = v[n + 1] / L[n, n]
        cosθn = sqrt(1 - sinθn^2)

        for n′ in n+1:N
            v[n′] = (v[n′] - sinθn * L[n′ - 1, n]) / cosθn
            L[n′, n + 1] = -sinθn * v[n′] + cosθn * L[n′ - 1, n]
        end
    end
    return L
end
chol(T::SymmetricToeplitz) = chol!(Matrix{eltype(T)}(undef, size(T, 1), size(T, 1)), T)'

function +(T::SymmetricToeplitz, u::UniformScaling)
    Tu = copy(T)
    Tu.vc[1] += u.λ
    Tu.vcvr_dft .+= u.λ
    return Tu
end
+(u::UniformScaling, T::SymmetricToeplitz) = T + u

transpose(T::Toeplitz) = Toeplitz(T.vr, T.vc)
adjoint(T::Toeplitz) = Toeplitz(conj.(T.vr), conj.(T.vc))
transpose(T::SymmetricToeplitz) = T
adjoint(T::SymmetricToeplitz) = T

@inline LinearAlgebra.Symmetric(T::SymmetricToeplitz) = T

Toeplitz(vc::AbstractVector, vr::AbstractVector) = Toeplitz(Vector(vc), Vector(vr))

# Some hacky broadcasted implementations as I don't have time to solve it properly. Just
# opts out of the fusion mechanism and stores intermediate state.
broadcasted(op, A::Toeplitz) = Toeplitz(op.(A.vc), op.(A.vr))
broadcasted(op, A::Toeplitz, B::Toeplitz) = Toeplitz(op.(A.vc, B.vc), op.(A.vr, B.vr))

broadcasted(op, S::SymmetricToeplitz) = SymmetricToeplitz(op.(S.vc))
function broadcasted(op, S::SymmetricToeplitz, S′::SymmetricToeplitz)
    return SymmetricToeplitz(op.(S.vc, S′.vc))
end

# """
#     mul!(C::Matrix, A::AbstractToeplitz, B::AbstractToeplitz)

# `O(prod(size(C)))` matrix multiplication for Toeplitz matrices. Follows from a skeleton of
# an algorithm on stackoverflow:
# https://stackoverflow.com/questions/15889521/product-of-two-toeplitz-matrices
# """
# function mul!(C::Matrix, A::AbstractToeplitz, B::AbstractToeplitz)
#     for q in 1:size(C, 2)
#         for p in 1:size(C, 1)
#             C[p, q]
#         end
#     end
#     return C
# end

# # function *(A::AbstractToeplitz, B::AbstractToeplitz)

# # end
