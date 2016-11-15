%% Generate a benchmark 1D data

if (exist('rankdiff_crit_test_1D.mat', 'file'))
  load('rankdiff_crit_test_1D.mat', 'f', 'trainSize', 'X_N', 'y_N', 'D', 'N', 'X_star', 'lambda');
else
  f = @(x) 0.25*(x+2).*sin(pi*x).^4;

  trainSize = 6;

  X_N = -0.3 + randn(1,trainSize)*0.3;
  y_N = f(X_N)';
  % set some noise on the training data
  y_N = y_N +  randn(size(y_N))*0.02;
  [D N] = size(X_N);

  X_star = 0 + randn(1,6)*0.15;
  lambda = size(X_star, 2);
end

%% Plot initial settings

x_surf = -1:0.02:1;
figure();
plot(x_surf, f(x_surf), 'k-');
ax = gca;
ax.YLim = [-0.5 1];
hold on;
plot(X_N, y_N, 'r+');
plot(X_star, -0.5*ones(size(X_star)), 'b*');

%% Construct GP model

modelOpts = struct('transformCoordinates', false, 'normalizeY', false);
model = GpModel(modelOpts, 0);
cmState = struct('xmean', -0.2, 'countiter', 1, 'sigma', 0.3, 'lambda', lambda, 'BD', 1, 'diagD', 1);
sampleOpts = struct('noiseReevals', 0, 'isBoundActive', 1, 'lbounds', -1, 'ubounds', 1, ...
  'flgDiagonalOnly', false, 'noiseHandling', false, 'xintobounds', @xintobounds);
model = model.train(X_N', y_N, cmState, sampleOpts);
model.trainGeneration = 1;
if (~iscell(model.likFcn))
  model.likFcn = {model.likFcn};
end
y_star = f(X_star');
[f_star, cov_star] = model.predict(X_star');

%% Plot GP prediction

plot(X_star, f_star, 'b+');
y_model = model.predict(x_surf');
plot(x_surf, y_model', 'b--');

%% Evaluate covariance function

K__X_star__X_N = feval(model.covFcn{:}, model.hyp.cov, X_N', X_star')'; % cross-covariances
K__X_N__X_N = feval(model.covFcn{:}, model.hyp.cov, X_N');    % train covariance (posterior?)

Kss = feval(model.covFcn{:}, model.hyp.cov, X_star', 'diag'); % self-variance

%% Posterior

% evaluate covariance matrix
K = K__X_N__X_N;
% evaluate mean vector
m = feval(model.meanFcn, model.hyp.mean, X_N');
% noise variance of likGauss
sn2 = exp(2*model.hyp.lik);
% Cholesky factor of covariance with noise
L = chol(K/sn2 + eye(N) + 0.0001*eye(N));
% inv(K+noise) * (y_N - mean)
alpha = solve_chol(L, y_N - m) / sn2;
% sqrt of noise precision vector
sW = ones(N,1) / sqrt(sn2);

%% Prediction

% evaluate mean function
ms = feval(model.meanFcn, model.hyp.mean, X_star');

% conditional mean fs|f (shorter form)
% Fmu = ms + K__X_star__X_N * alpha;

% Inverse of the covariance
K_inv = solve_chol(L, eye(N));

% conditional mean fs|f
Fmu = ms + K__X_star__X_N * K_inv * (1/sn2) * (y_N - m);

% %% This is not necessary:
% 
% Ltril = all(all(tril(L,-1)==0));       % is L an upper triangular matrix?
% if (Ltril)   % L is triangular => use Cholesky parameters (alpha,sW,L)
%   V  = L'\(repmat(sW,1,lambda).*K__X_star__X_N);
%   fs2 = Kss - sum(V.*V,1)';        % predictive variances
% else         % L is not triangular => use alternative parametrisation
%   fs2 = Kss + sum(K__X_star__X_N.*(L*K__X_star__X_N),1)';  % predictive variances
% end
% % remove numerical noise i.e. negative variances
% Fs2 = max(fs2, 0);
% 
% % marginalization
% [Lp, Ymu, Ys2] = feval(model.likFcn{:}, model.hyp.lik, [], Fmu(:), Fs2(:));

%% Select one of the points

s = 3;
withoutS = [1:(s-1), (s+1):lambda]';

X_star_m = X_star(:,withoutS);
X_N_p    = [X_N X_star(:,s)];
X_s      = X_star(:,s);

%% Calculate modified covariances and prediction as if X_s would be in the train set

% covariances
K__X_star_m__X_N_p = feval(model.covFcn{:}, model.hyp.cov, X_N_p', X_star_m')';
K__X_N_p__X_N_p = feval(model.covFcn{:}, model.hyp.cov, X_N_p', []);
% evaluate mean vectors
m_m  = feval(model.meanFcn, model.hyp.mean, X_N_p');
ms_m = feval(model.meanFcn, model.hyp.mean, X_star_m');
% noise variance of likGauss
sn2 = exp(2*model.hyp.lik);
% Cholesky factor of covariance with noise
Lp = chol(K__X_N_p__X_N_p/sn2+eye(N+1) + 0.0001*eye(N+1));
% Covariance * y_N
Kp_inv = solve_chol(Lp, eye(N+1));

%% Predictive mean (Example)

Y_s = f(X_s)*1.1;
Fmu_m = ms_m + K__X_star_m__X_N_p * Kp_inv * (1/sn2) * ([y_N; Y_s] - m_m);

%% Calculate inequalitiy boudnaries

A = K__X_star_m__X_N_p * Kp_inv * (1/sn2);

M = NaN(lambda-1,lambda-1);

for i = 1:(lambda-1)
  for j = (i+1):(lambda-1)
    h_k = A(i,1:(end-1)) * y_N;
    h_l = A(j,1:(end-1)) * y_N;
    M(i,j) = (h_k - h_l) / (A(i,end) - A(j,end));
  end  
end

thresholds = M(:);
thresholds = sort(thresholds(~isnan(thresholds)));

%% Sample modified rankings

n_sample = 1000;
diff = thresholds(end) - thresholds(1);
ub = thresholds(end) + 1*diff;
lb = thresholds(1)   - 1*diff;
y_space = linspace(lb, ub, n_sample);
last_rank = ranking(Fmu(withoutS));
y_ths   = [];
y_ranks = [];
for y = y_space
  Fmu_m = ms_m + K__X_star_m__X_N_p * Kp_inv * (1/sn2) * ([y_N; y] - m_m);
  this_rank = ranking(Fmu_m);
  if (~all(this_rank == last_rank))
    y_ths = [y_ths; y];
    y_ranks = [y_ranks; last_rank(:)'];
    last_rank = this_rank;
  end
end
y_ranks = [y_ranks; this_rank'];

%% Plot the two extreme rankings

for y = [y_ths(1) - 0.1, y_ths(end)]
  Ks = feval(model.covFcn{:}, model.hyp.cov, X_N_p', x_surf')';
  ms_extreme = feval(model.meanFcn, model.hyp.mean, x_surf');
  y_extreme = ms_extreme + Ks * Kp_inv * (1/sn2) * ([y_N; y] - m_m);
  plot(x_surf, y_extreme, 'm--');
  Fmu_m = ms_m + K__X_star_m__X_N_p * Kp_inv * (1/sn2) * ([y_N; y] - m_m);
  plot(X_star_m, Fmu_m, 'm+')
  plot(X_s, y, 'r*');
end

legend('True function', 'GP train set of size N', '\lambda Sampled points (on x-axis)', ...
  '\lambda Sampled points', 'Mean prediction based on the N-train set', ...
  'Extreme ordering GP with (N+1) trainset');
%% Topological sort

nt = size(thresholds,1);
S = -1 * ones(nt, lambda-1);
Ok = false(nt,1);
for t = 1:nt
  G = (M < thresholds(t)) + (M' >= thresholds(t));
  [S(t,:), Ok(t)] = toposort(G);
  
  Y_s = thresholds(t)+sqrt(eps);
  Fmu_m = ms_m + K__X_star_m__X_N_p * Kp_inv * (1/sn2) * [y_N; Y_s];
  disp([Ok(t) ranking(Fmu_m)'; NaN S(t,:)]);
end