module DistributionTest

using OnlineStats, FactCheck, Distributions, DataFrames

facts("Distributions") do

#------------------------------------------------------------------------------#
#                                                                    Bernoulli #
#------------------------------------------------------------------------------#

    context("Bernoulli") do
        o = FitBernoulli()
        o = FitBernoulli(rand(Bernoulli(), 10))
        o = onlinefit(Bernoulli, rand(Bernoulli(), 10))

        n1 = rand(1:1_000_000)
        n2 = rand(1:1_000_000)
        p = rand()
        x1 = rand(Bernoulli(p), n1)
        x2 = rand(Bernoulli(p), n2)
        x = [x1, x2]

        o = OnlineStats.onlinefit(Bernoulli, x1)
        @fact FitBernoulli(x1).d.p => roughly(Bernoulli(mean(x1)).p)
        @fact FitBernoulli().d.p => 0.
        @fact o.d.p => roughly(mean(x1))
        @fact o.n => n1

        OnlineStats.update!(o, x2)
        @fact o.d.p => roughly(mean(x))
        @fact o.n => n1 + n2

        @fact state(o) => [o.d, o.n]
        @fact statenames(o) => [:dist, :nobs]
        @fact typeof(DataFrame(o)) => DataFrame
        o2 = copy(o)
        @fact DataFrame(o2) => DataFrame(dist = o.d, nobs = n1 + n2)
        @fact mean(o2.d) => roughly(mean(x))
        @fact nobs(o) => n1 + n2

        o = onlinefit(Bernoulli, x1, ExponentialWeighting(.01))
        @fact weighting(o) => ExponentialWeighting(.01)

        o = onlinefit(Bernoulli, x1, ExponentialWeighting(1000))
        @fact weighting(o) => ExponentialWeighting(1000)
    end

#------------------------------------------------------------------------------#
#                                                                         Beta #
#------------------------------------------------------------------------------#
    context("Beta") do
        o = FitBeta()
        o = FitBeta(rand(10))
        o = FitBeta([.1, .9])
        o = onlinefit(Beta, rand(10), ExponentialWeighting(.01))

        n1 = rand(1:1_000_000)
        n2 = rand(1:1_000_000)
        α, β = rand(1:0.1:10, 2)
        x1 = rand(Beta(α, β), n1)
        x2 = rand(Beta(α, β), n2)
        x = [x1, x2]

        o = onlinefit(Beta, x1)
        @fact mean(o.d) => roughly(mean(x1))
        @fact var(o.d) => roughly(var(x1))
        @fact o.n => n1

        OnlineStats.update!(o, x2)
        @fact mean(o.d) => roughly(mean(x))
        @fact var(o.d) => roughly(var(x))
        @fact o.n => n1 + n2
        @fact statenames(o) => [:dist, :nobs]
        @fact state(o) => [o.d, o.n]
        o2 = copy(o)
        @fact DataFrame(o2) => DataFrame(o)
        @fact DataFrame(o2) => DataFrame(dist = o.d, nobs = n1 + n2)
    end


#------------------------------------------------------------------------------#
#                                                                     Binomial #
#------------------------------------------------------------------------------#
    context("Binomial") do
        o = FitBinomial(n = 10)
        o = FitBinomial(rand(Binomial(10, .5), 10), n = 10)
        o = FitBinomial(n = 5, ExponentialWeighting(.001))
        o = onlinefit(Binomial, rand(Binomial(10,.5), 10), StochasticWeighting(.6), n = 10)
        o = FitBinomial(n = 5, ExponentialWeighting(.001))
        @fact nobs(o) => 0
        @fact weighting(o) => ExponentialWeighting(.001)

        n1 = rand(1:1_000_000)
        n2 = rand(1:1_000_000)
        ntrials = rand(1:1000)
        p = rand()
        x1 = rand(Binomial(ntrials, p), n1)
        x2 = rand(Binomial(ntrials, p), n2)
        x = [x1, x2]

        o = onlinefit(Binomial, x1, n = ntrials)
        @fact mean(o) => roughly(mean(x), .01)
        @fact var(o) => var(o.d)
        @fact o.d.n => ntrials
        @fact o.d.p => roughly(sum(x1) / (ntrials * n1))
        @fact o.n => n1
        @fact mean(FitBinomial().d) => 0.
        @fact mean(onlinefit(Binomial, [0])) => 0.
        @fact mean(FitBinomial(zeros(Int, 10))) => 0.
        @fact mean(FitBinomial(ones(Int, 10))) => 1.

        @fact OnlineStats.update!(o, x2) => nothing
        @fact o.d.n => ntrials
        @fact o.d.p => roughly(sum(x) / (ntrials * (n1 + n2)))
        @fact o.n => n1 + n2

        @fact state(o) => [o.d, o.n]
        o2 = copy(o)
        @fact statenames(o2) => [:dist, :nobs]
        @fact DataFrame(o2) => DataFrame(dist = o.d, nobs = o.n)
    end



#------------------------------------------------------------------------------#
#                                                                    Dirichlet #
#------------------------------------------------------------------------------#
    context("Dirichlet") do
        o = FitDirichlet()

        n1 = rand(1:1_000_000)
        n2 = rand(1:1_000_000)
        αlength = rand(3:20)
        α = rand(.5:.1:20, αlength)
        x1 = rand(Dirichlet(α), n1)'
        o = FitDirichlet(x1)
        @fact weighting(o) => EqualWeighting()
        x2 = rand(Dirichlet(α), n2)'
        x = [x1; x2]

        o = onlinefit(Dirichlet, x1)
        @fact o.meanlogx => vec(mean(log(x1), 1))
        @fact o.n => n1

        updatebatch!(o, x2)
        @fact length(o.d.alpha) => αlength


        @fact o.d.alpha => roughly(fit(Dirichlet, x').alpha, .01) "failure ok. fit() is to blame"
        @fact o.n => n1 + n2

        @fact state(o) => [o.d, o.n]
        @fact statenames(o) => [:dist, :nobs]
        o2 = copy(o)
        @fact state(o2)[2] => state(o)[2]
        @fact names(DataFrame(o)) => statenames(o)
        @fact DataFrame(o)[1, end] => nobs(o)
    end

#------------------------------------------------------------------------------#
#                                                                  Exponential #
#------------------------------------------------------------------------------#
    context("Exponential") do
        o = FitExponential()
        o = FitExponential(rand(Exponential(), 10))
        o = onlinefit(Exponential, rand(Exponential(), 10))
        @fact weighting(o) => EqualWeighting()

        n1 = rand(1:1_000_000, 1)[1]
        n2 = rand(1:1_000_000, 1)[1]
        θ = rand(1:1000, 1)[1]
        x1 = rand(Exponential(θ), n1)
        x2 = rand(Exponential(θ), n2)
        x = [x1, x2]

        o = onlinefit(Exponential, x1)
        @fact o.d.β => roughly(mean(x1))
        @fact o.n => n1
        @fact nobs(o) => n1

        OnlineStats.update!(o, x2)
        @fact o.d.β => roughly(mean(x))
        @fact o.n => n1 + n2

        o1 = copy(o)
        @fact state(o) => [o.d, o.n]
        @fact statenames(o) => [:dist, :nobs]
        @fact state(o1) => state(o)
        @fact DataFrame(o) => DataFrame(dist = o.d, nobs = o.n)
    end


#------------------------------------------------------------------------------#
#                                                                        Gamma #
#------------------------------------------------------------------------------#
    context("Gamma") do
        o = FitGamma()
        o = FitGamma(rand(Gamma(), 10))
        o = onlinefit(Gamma, rand(Gamma(), 10))

        n1 = rand(1:1_000_000, 1)[1]
        n2 = rand(1:1_000_000, 1)[1]
        α, β = rand(1:0.1:100, 2)
        x1 = rand(Gamma(α, β), n1)
        x2 = rand(Gamma(α, β), n2)
        x = [x1, x2]

        o = FitGamma()
        @fact o.d => Gamma()
        @fact nobs(o) => 0
        @fact mean(o) => mean(Gamma())

        o = FitGamma(x1)
        @fact mean(o) => roughly(mean(x1))
        @fact FitGamma(x1).d => onlinefit(Gamma, x1).d
        @fact FitGamma(x1).n => onlinefit(Gamma, x1).n
        o = onlinefit(Gamma, x1)
        @fact onlinefit(Gamma, x1).d => FitGamma(x1).d
        @fact mean(o.m) => roughly(mean(x1))
        @fact mean(o.mlog) => roughly(mean(log(x1)))
        @fact o.n => n1

        OnlineStats.update!(o, x2)
        @fact state(o) => [o.d, o.n]
        @fact statenames(o) => [:dist, :nobs]
        @fact mean(o.m) => roughly(mean(x))
        @fact mean(o.mlog) => roughly(mean(log(x)))
        @fact o.n => n1 + n2

        o1 = copy(o)
        @fact state(o1) => state(o)
        @fact o.n => n1 + n2
        @fact DataFrame(o) => DataFrame(dist = o.d, nobs = o.n)
    end

#------------------------------------------------------------------------------#
#                                                                  Multinomial #
#------------------------------------------------------------------------------#
    context("Multinomial") do
        o = FitMultinomial()
        o = FitMultinomial(rand(Multinomial(5, [.2, .3, .5]), 10)')
        o = onlinefit(Multinomial, rand(Multinomial(5, [.2, .3, .5]), 10)')

        n1 = rand(10_000:100_000, 1)[1]
        n2 = rand(10_000:100_000, 1)[1]
        n = rand(1:100)
        ncat = rand(1:20)
        p = rand(ncat)
        p /= sum(p)
        x1 = rand(Multinomial(n, p), n1)'
        x2 = rand(Multinomial(n, p), n2)'
        x = [x1; x2]

        o = onlinefit(Multinomial, x1)
        @fact o.d.n => n
        @fact o.d.p => roughly(vec(sum(x1, 1) / (n * n1)))
        @fact o.n => n1
        @fact nobs(o) => n1


        OnlineStats.update!(o, x2)
        @fact o.d.n => n
        @fact o.d.p => roughly(vec(sum(x, 1) / (n * (n1 + n2))))
        @fact o.n => n1 + n2

        o1 = copy(o)
        @fact state(o) => [o.d, o.n]
        @fact statenames(o) => [:dist, :nobs]
        @fact o1.d.n => n
        @fact o1.d.p => roughly(vec(sum(x, 1) / (n * (n1 + n2))))
        @fact o1.n => n1 + n2

        @fact names(DataFrame(o)) => statenames(o)
        @fact DataFrame(o) => DataFrame(dist = o.d, nobs = o.n)
    end

#------------------------------------------------------------------------------#
#                                                                     MvNormal #
#------------------------------------------------------------------------------#
    context("MvNormal") do
        n1 = rand(1:1_000_000)
        n2 = rand(1:1_000_000)
        d = rand(3:10)
        x1 = rand(MvNormal(zeros(d), eye(d)), n1)'
        x2 = rand(MvNormal(zeros(d), eye(d)), n2)'
        x = [x1;  x2]

        o = onlinefit(MvNormal, x1)
        FitMvNormal(x1)
        FitMvNormal(d)
        @fact o.d.μ => roughly(vec(mean(x1, 1)))
        @fact mean(o.c) => roughly(vec(mean(x1, 1)))
        @fact cov(o.c) => roughly(cov(x1))
        @fact cov(o.c) => roughly(o.d.Σ.mat)
        @fact o.n => n1

        OnlineStats.updatebatch!(o, x2)
        @fact o.d.μ => roughly(vec(mean(x, 1)))
        @fact mean(o.c) => roughly(vec(mean(x, 1)))
        @fact cov(o.c) => roughly(cov(x))
        @fact o.n => n1 + n2

        o1 = copy(o)
        @fact o1.d.μ => roughly(vec(mean(x, 1)))
        @fact mean(o1.c) => roughly(vec(mean(x, 1)))
        @fact cov(o1.c) => roughly(cov(x))
        @fact o1.n => n1 + n2
        @fact state(o) => [o.d, o.n]

        o = FitMvNormal(2)
        update!(o, randn(2))
        @fact nobs(o) => 1
    end


#------------------------------------------------------------------------------#
#                                                                       Normal #
#------------------------------------------------------------------------------#
    context("Normal") do
        o = FitNormal()
        o = FitNormal(randn(10))
        @fact weighting(o) => EqualWeighting()

        n1 = rand(1:1_000_000, 1)[1]
        n2 = rand(1:1_000_000, 1)[1]
        x1 = randn(n1)
        x2 = randn(n2)
        x = [x1, x2]

        o = onlinefit(Normal, x1)
        @fact mean(o.v) => roughly(mean(x1))
        @fact mean(o.d) => roughly(mean(o.v))
        @fact var(o.v) => roughly(var(x1))
        @fact o.n => n1

        update!(o, x2)
        @fact o.d.σ => roughly(std(x))
        @fact o.d.μ => roughly(mean(x))
        @fact mean(o.v) => roughly(mean(x))
        @fact var(o.v) => roughly(var(x))
        @fact o.n => n1 + n2

        o1 = copy(o)
        @fact statenames(o) => [:dist, :nobs]
        @fact state(o) => [o.d, o.n]
        @fact state(o1) => state(o)
        @fact o1.d.σ => roughly(std(x))
        @fact o1.d.μ => roughly(mean(x))
        @fact mean(o1.v) => roughly(mean(x))
        @fact var(o1.v) => roughly(var(x))
        @fact o1.n => n1 + n2

        x = randn(100)
        o1 = FitNormal(x)
        o2 = onlinefit(Normal, x)
        @fact o1.d => o2.d
        @fact nobs(o1) => nobs(o2)
    end

end # facts
end # module
