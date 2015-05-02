
#-------------------------------------------------------# Type and Constructors
type CovarianceMatrix{W <: Weighting} <: OnlineStat
    A::Matrix{Float64}    # X' * X / n
    B::Vector{Float64}    # X * 1' / n (column means)
    n::Int64              # number of observations used
    weighting::W
end

# (p by p) covariance matrix from an (n by p) data matrix
function CovarianceMatrix{T <: Real}(x::Matrix{T}, wgt::Weighting = default(Weighting))
    o = CovarianceMatrix(wgt; p = size(x, 2))
    updatebatch!(o, x)
    o
end

CovarianceMatrix(wgt::Weighting = default(Weighting); p = 2) =
    CovarianceMatrix(zeros(p,p), zeros(p), 0, wgt)


#-----------------------------------------------------------------------# state
statenames(o::CovarianceMatrix) = [:μ, :Σ, :nobs]

state(o::CovarianceMatrix) = Any[mean(o), cov(o), o.n]


#---------------------------------------------------------------------# update!
function updatebatch!(o::CovarianceMatrix, x::MatF)
    n2 = size(x, 1)
    λ = weight(o, n2)
    o.n += n2

    # Update B
    smooth!(o.B, vec(mean(x,1)), λ)
    # Update A
    BLAS.syrk!('L', 'T', λ, x / sqrt(n2), 1 - λ, o.A)
    return
end


#-----------------------------------------------------------------------# state
Base.mean(o::CovarianceMatrix) = return o.B

Base.var(o::CovarianceMatrix) = diag(cov(o::CovarianceMatrix))

Base.std(o::CovarianceMatrix) = sqrt(var(o::CovarianceMatrix))

function Base.cov(o::CovarianceMatrix)
    B = o.B
    p = size(B, 1)
    covmat = o.n / (o.n - 1) * (o.A - BLAS.syrk('L','N',1.0, B))
    for j in 1:p
        for i in 1:j - 1
            covmat[i, j] = covmat[j, i]
        end
    end
    return covmat
end

function Base.cor(o::CovarianceMatrix)
    covmat = cov(o)
    V = 1 ./ sqrt(diag(covmat))
    covmat = V .* covmat .* V'
    return covmat
end




#------------------------------------------------------------------------# Base
function Base.merge!(c1::CovarianceMatrix, c2::CovarianceMatrix)
    λ = mergeweight(c1, c2)
    c1.A = smooth(c1.A, c2.A, λ)
    c1.B = smooth(c1.B, c2.B, λ)
    c1.n += n2
end