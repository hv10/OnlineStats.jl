# Author: Josh Day <emailjoshday@gmail.com>

export Summary

#------------------------------------------------------------------------------#
#----------------------------------------------------------------# Summary Type
type Summary <: ContinuousUnivariateOnlineStat
  mean::Vector{Float64}
  var::Vector{Float64}
  max::Vector{Float64}
  min::Vector{Float64}
  n::Vector{Int64}
  nb::Vector{Int64}
end

@doc doc"""
Create Summary object

fields (each is Vector): `mean`, `var`, `max`, `min`, `n`, `nb`
""" ->
function Summary(y::Vector)
  Summary([mean(y)], [var(y)], [maximum(y)], [minimum(y)], [length(y)], [1])
end

#------------------------------------------------------------------------------#
#---------------------------------------------------------------------# update!
function update!(obj::Summary, newdata::Vector, add::Bool = false)
  n1::Int = obj.n[end]
  n2::Int = length(newdata)
  n::Int = n1 + n2

  μ1::Float64 = obj.mean[end]
  μ2::Float64 = mean(newdata)
  δ::Float64 = μ2 - μ1

  ss1::Float64 = (n1 - 1) * obj.var[end]
  ss2::Float64 = vecnorm(newdata - μ2) ^ 2

  if add
    # n
    push!(obj.n, n)

    # nb
    push!(obj.nb, obj.nb[end] + 1)

    # mean
    push!(obj.mean, μ1 + n2 / n * δ)

    # var
    push!(obj.var, (ss1 + ss2 + n1 * n2 / n * δ^2) / (n - 1))

    # maximum and minimum
    push!(obj.max, maximum([obj.max[end], newdata]))
    push!(obj.min, minimum([obj.min[end], newdata]))

  else
    # n
    obj.n[end] = n

    # nb
    obj.nb[end] = obj.nb[end] + 1

    # mean
    obj.mean[end] = μ1 + n2 / n * δ

    # var
    obj.var[end] = (ss1 + ss2 + n1 * n2 / n * δ^2) / (n - 1)

    # maximum and minimum
    obj.max[end] = maximum([obj.max[end], newdata])
    obj.min[end] = minimum([obj.min[end], newdata])
  end
  return obj
end



#------------------------------------------------------------------------------#
#-----------------------------------------------------------------------# state
function state(obj::Summary)
  println(join(("mean = ", obj.mean[end])))
  println(join(("var = ", obj.var[end])))
  println(join(("max = ", obj.max[end])))
  println(join(("min = ", obj.min[end])))
  println(join(("n = ", obj.n[end])))
  println(join(("nb = ", obj.nb[end])))
end


#------------------------------------------------------------------------------#
#----------------------------------------------------------------# Base.convert
function Base.convert(::Type{DataFrames.DataFrame}, obj::Summary)
  df = DataFrames.DataFrame()
  df[:mean] = obj.mean
  df[:var] = obj.var
  df[:max] = obj.max
  df[:min] = obj.min
  df[:n] = obj.n
  df[:nb] = obj.nb
  return df
end


#------------------------------------------------------------------------------#
#---------------------------------------------------------# Interactive Testing

# x1 = rand(100)
# x2 = rand(112)
# x3 = rand(103)

# obj = OnlineStats.Summary(x1)
# OnlineStats.update!(obj, x2, true)
# OnlineStats.update!(obj, x3, false)

