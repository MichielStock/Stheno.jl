using Stheno, Plots



###########################  Define and inspect our model  ###########################

# Define the vanilla GP-regression generative model.
function model(gpc)

    # Define a smooth latent process.
    f = 1.5 * GP(EQ(), gpc)

    # Define a latent noise process.
    noise = GP(Noise(1e-2), gpc)

    # Sum them to get the process of which we shall make observations.
    y = f + noise

    # Return all three processes so that we can inspect all of them.
    return f, noise, y
end

# Generate some input locations and sample from the prior.
rng, N = MersenneTwister(123546), 500;
X_prior = sort(rand(rng, N) * 10);
f, noise, y = model(GPC());

# Take a look at the mean function and kernel of y.
@show mean(y), kernel(y);

# Take a look at the cross-covariance between f and y.
@show kernel(f, y);

# Inspect the cross-covariance between noise and y.
@show kernel(noise, y);



###########################  Sample jointly from the prior  ###########################

# Sample jointly from the prior distribution over the three processes.
fX, noiseX, yX = rand(rng, [f, noise, y], [X_prior, X_prior, X_prior]);


#######################  Do posterior inference give a few samples  #######################

# Sample a few points from the prior and compute the posterior processes.
N = 15;
X = sort(rand(rng, N) * 10);
ŷ = rand(rng, y, X);
f′, noise′, y′ = (f, noise, y) | (y(X) ← ŷ);

# There appear to be some substantial numerical problems associated with generating samples
# jointly from all three processes, thus only f′ and noise′ are considered.
Nplot, S = 500, 100;
Xplot = linspace(-2.0, 12.0, Nplot);
f′Xp, noise′Xp = rand(rng, [f′, noise′], [Xplot, Xplot], S);

# Get posterior mean and marginals f′ and y′ and write them for plotting.
μ′f, σ′f = marginals(f′, Xplot);
σ′y = diag_std(y′, Xplot);

####################################  Plot results  ####################################

plotly();

prior_plot = plot(X_prior, fX, label="f");
scatter!(prior_plot, X_prior, noiseX,
    label="noise",
    markershape=:xcross,
    markerstrokewidth=0.0,
    markersize=2);
scatter!(prior_plot, X_prior, yX,
    label="y",
    markershape=:xcross,
    markerstrokewidth=0.0,
    markersize=2);
plot!(prior_plot, X_prior, fX + noiseX - yX,
    label="f + noise - y",
    linecolor=:red);

posterior_plot = plot(Xplot, f′Xp;
    linecolor=:blue,
    linealpha=0.2,
    legend=false);
plot!(posterior_plot, Xplot, μf′;
    linewidth=2.0,
    linecolor=:blue);
plot!(posterior_plot, Xplot, [μf′ μf′];
    linewidth=0.0,
    fillrange=[μf′ .- 3 .* σy′, μf′ .+ 3 * σy′],
    fillalpha=0.3,
    fillcolor=:red);
plot!(posterior_plot, Xplot, [μf′ μf′];
    linewidth=0.0,
    fillrange=[μf′.- 3  .* σf′ μf′ .+ 3 .* σf′],
    fillalpha=0.5,
    fillcolor=:blue);
scatter!(posterior_plot, X, ŷ;
    markercolor=:red,
    markershape=:circle,
    markerstrokewidth=0.0,
    markersize=4,
    markeralpha=0.7,
    legend=false);
joint_plot = plot(prior_plot, posterior_plot, layout=(2, 1));
display(joint_plot);