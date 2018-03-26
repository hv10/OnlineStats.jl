#-----------------------------------------------------------------------# Weight
@recipe function f(wt::Weight; nobs=50)
    xlab --> "Number of Observations"
    ylab --> "Weight Value"
    label --> name(wt)
    ylim --> (0, 1)
    w --> 2
    [wt(i) for i in 1:nobs]
end

#-----------------------------------------------------------------------# Fallback
@recipe function f(o::OnlineStat)
    legend --> false
    axis --> false
    grid --> false
    ylim --> (0, 1)
    xlim --> (0, 1)
    annotations --> [(.5, .75, name(o) * ":"), (.5, .4, string(value(o)))]
    zeros(0)
end

#-----------------------------------------------------------------------# residual plot
@recipe function f(o::OnlineStat{VectorOb}, x::AbstractMatrix, y::AbstractVector)
    ylab --> "Residual"
    xlab --> "Observation Index"
    legend --> false
    @series begin
        linetype --> :scatter
        ŷ = predict(o, x)
        eachindex(y), y - ŷ
    end
end

@recipe function f(o::OnlineStat{XY})
    ylab --> "beta_j"
    xlab --> "j"
    seriestype --> :scatter
    coef(o)
end

@recipe function f(o::Series{VectorOb}, x::AbstractMatrix, y::AbstractVector)
    for stat in o.stats
        @series begin stat end
    end
end


#-----------------------------------------------------------------------# StatCollection
@recipe function f(s::StatCollection)
    if :layout in keys(plotattributes)
        for stat in s.stats
            @series begin stat end
        end 
    else  # hack to ensure series aren't sent to wrong subplots
        layout --> length(s.stats)
        for i in eachindex(s.stats)
            @series begin 
                subplot --> i 
                s.stats[i]
            end
        end
    end
end

#-----------------------------------------------------------------------# AutoCov
@recipe function f(o::AutoCov)
    xlabel --> "Lag"
    ylabel --> "Autocorrelation"
    ylim --> (0, 1)
    seriestype --> :scatter
    autocor(o)
end

#-----------------------------------------------------------------------# CovMatrix
@recipe function f(o::CovMatrix; corr = false)
    seriestype --> :heatmap
    corr ? cor(o) : cov(o)
end

#-----------------------------------------------------------------------# Hist 
@recipe f(o::Hist) = o.alg

@recipe f(o::FixedBins{closed}) where {closed} =
    Histogram(o.edges, o.counts, closed)

@recipe function f(o::AdaptiveBins; sticks=false)
    y = [o[i] for i in 0:(length(o.value) + 1)]
    out = first.(y), last.(y) 
    @series begin 
        seriestype --> :line
        fillto --> 0 
        alpha --> .4
        linewidth --> 0
        out
    end 
    if sticks 
        @series begin 
            seriestype --> :sticks 
            out
        end
    end
end

#-----------------------------------------------------------------------# CountMap
@recipe function f(o::CountMap)
    seriestype --> :bar 
    collect(keys(o)), collect(values(o))
end

#-----------------------------------------------------------------------# Partition
@recipe f(o::AbstractPartition, fun=value) = o.parts, fun

@recipe function f(parts::Vector{Part{T, O}}, fun) where {T, O}
    color --> :viridis
    sort!(parts)
    y = map(part -> fun(part.stat), parts)
    x = midpoint.(parts)
    if parts[1].a isa Number
        xlim --> (parts[1].a, parts[end].b)
    end
    if y[1] isa Number
        lab --> name(parts[1].stat, false, false)
        x, y
    elseif y[1] isa Tuple{VectorOb, VectorOb}  # Histogram
        x2, y2, z = eltype(x)[], [], []
        n = sum(nobs, parts)
        for i in eachindex(y)
            values, counts = y[i]
            for j in eachindex(values)
                push!(x2, x[i])
                push!(y2, values[j])
                push!(z, counts[j] / n)
            end
        end
        seriestype --> :scatter 
        marker_z --> log.(z)
        ylab --> "log(prob)"
        markerstrokewidth --> 0
        x2, y2
    elseif y[1] isa VectorOb
        lab --> name(parts[1].stat, false, false)
        y2 = plotshape(y)
        x2 = eltype(x) == Char ? string.(x) : x  # Plots can't handle Char
        @show x2
        if length(y[1]) == 2 
            fillto --> y2[:, 1]
            alpha --> .4
            x2, y2[:, 2]
        else
            x2, y2 
        end
    elseif y[1] isa AbstractDict  # CountMap
        kys = []
        for item in y, ky in keys(item)
            ky ∉ kys && push!(kys, ky)
        end
        sort!(kys)
        y2 = 
        @series begin 
            lab --> reshape(kys, (1, length(kys)))
            ylim --> (0, 1)
            linewidth --> .5
            seriestype --> :bar
            bar_widths --> [p.b - p.a for p in parts]
            y = plotshape(map(x -> reverse(cumsum(probs(x.stat, reverse(kys)))), parts))
            x, y
        end
    end
end

plotshape(v::Vector{<:VectorOb}) = [v[i][j] for i in eachindex(v), j in eachindex(v[1])]

#-----------------------------------------------------------------------# NBClassifier 
@recipe function f(o::NBClassifier)
    kys = collect(keys(o))
    layout --> nvars(o) + 1
    for j in 1:nvars(o) 
        stats = o[j]
        for (i, s) in enumerate(stats)
            @series begin 
                title --> "Var $j"
                legend --> false 
                subplot --> j 
                s
            end
        end
    end
    @series begin 
        subplot --> nvars(o) + 1
        label --> reshape(kys, 1, length(kys))
        framestyle := :none
        zeros(0, length(kys))
    end
end
