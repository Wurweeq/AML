clear all;
close all;

%%  computational cost
% Set parameters for computational cost
nb_try = 3;
n_jump = 100;

% Set default values for data
n_limites = [100, 4000];        % number of samples
data.D =    1;                  % dimension of data
data.scale = 10;                % scale of dimensions
data.noise = 0.1;               % scale of noise
data.noiseType = 'gauss';       % type of noise ('gauss' or 'unif')

clear svr_options
% SVR OPTIONS
svr_options.svr_type    = 0;    % 0: epsilon-SVR, 1: nu-SVR
svr_options.C           = 1;    % set the parameter C of C-SVC, epsilon-SVR, and nu-SVR 
svr_options.epsilon     = 0.1;  % set the epsilon in loss function of epsilon-SVR 
svr_options.kernel_type = 2;    % 0: linear: u'*v, 1: polynomial: (gamma*u'*v + coef0)^degree, 2: radial basis function: exp(-gamma*|u-v|^2)
svr_options.kernel  = 'gaussian';
svr_options.lengthScale = 0.01;  % lengthscale parameter (~std dev for gaussian kernel)
svr_options.probabilities   = 0;    % whether to train a SVR model for probability estimates, 0 or 1 (default 0);
svr_options.useBias         = 0;    % add bias to the model (for custom basis matrix)

clear rvr_options
%Set RVR OPTIONS%
rvr_options.useBias = 0;
rvr_options.maxIts  = 500;
rvr_options.kernel  = 'gaussian';
rvr_options.lengthScale = svr_options.lengthScale;
rvr_options.BASIS = [];

%initialization values of interest
gf_svr      = zeros(nb_try, length(n_limites(1): n_jump : n_limites(2)));
gf_rvr      = zeros(nb_try, length(n_limites(1): n_jump : n_limites(2)));
time_svr    = zeros(nb_try, length(n_limites(1): n_jump : n_limites(2)));
time_rvr    = zeros(nb_try, length(n_limites(1): n_jump : n_limites(2)));
sv_svr      = zeros(nb_try, length(n_limites(1): n_jump : n_limites(2)));
sv_rvr      = zeros(nb_try, length(n_limites(1): n_jump : n_limites(2)));

%computational cost
for k1 = 1: 1 : nb_try 
    k2 = 1;
    for n = n_limites(1): n_jump : n_limites(2)
        disp(' ');
        disp(n);
        disp(' ');
        % Generate True function and data
        data.N = n;
        [x, y_true, y] = generateSinc(data, k1);
        
        % Define inputs
        x_svr = normalize(x);
        x_rvr = normalize(x);
             
        % Train SVR Model
        clear model y_svr tstart
        tstart = tic;
        model = svr_train(y, x_svr, svr_options);
        [y_svr]  = svr_predict(x_svr, model);
%         [y_svr, model] = svm_regressor(x_svr, y, svr_options, []);
        time_svr(k1,k2) = toc(tstart);    
        
        %goodness of fit
        gf_svr(k1,k2) = gfit2(y,y_svr,'2');
        
        % number of support vectors
        sv_svr(k1,k2) = model.totalSV;
        

        %Train RVR Model
        clear model y_rvr tstart
        tstart = tic;
        [model] = rvr_train(x_rvr, y, rvr_options);
        [y_rvr,~,~] = rvr_predict(x_rvr,  model);
        time_rvr(k1,k2) = toc(tstart);

        %goodness of fit
        gf_rvr(k1,k2) = gfit2(y,y_rvr,'2');
        
        %number of relevance vectors
        sv_rvr(k1,k2) = length(model.RVs_idx);
        
        k2 = k2+1;
        
    end
 end

% plot time
figure(1)
hold on
nb_samples = n_limites(1): n_jump : n_limites(2);
boundedline(nb_samples, mean(time_svr,1), std(time_svr, 0, 1), 'b', nb_samples, mean(time_rvr,1), std(time_rvr, 0, 1), 'r', 'transparency', 0.1, 'alpha');
hold off

axis([0 inf 0 inf]);
legend({'SVR', 'RVR'}, 'Location', 'NorthWest', 'Interpreter', 'LaTex');
title('Computational time comparison (mean $\pm$ std)', 'Interpreter', 'LaTex');
xlabel('Number of datapoints', 'Interpreter', 'LaTex');
ylabel('Time (seconds)', 'Interpreter', 'LaTex')

%% plot gf
figure(2)
hold on
nb_samples = n_limites(1): n_jump : n_limites(2);
boundedline(nb_samples, mean(gf_svr,1), std(gf_svr, 0, 1), 'b', nb_samples, mean(gf_rvr,1), std(gf_rvr, 0, 1), 'r', 'transparency', 0.1, 'alpha');
hold off

axis([0 inf 0 inf]);
legend({'SVR', 'RVR'}, 'Location', 'NorthWest', 'Interpreter', 'LaTex');
title('Error comparison (mean $\pm$ std)', 'Interpreter', 'LaTex');
xlabel('Number of datapoints', 'Interpreter', 'LaTex');
ylabel('Normalized Mean Square Error', 'Interpreter', 'LaTex')

%% plot sv
figure(3)
subplot(1,2,1);
nb_samples = n_limites(1): n_jump : n_limites(2);
boundedline(nb_samples, mean(sv_svr,1), std(sv_svr, 0, 1), 'b', 'transparency', 0.1, 'alpha');
title('SVR Sparsity (mean $\pm$ std)', 'Interpreter', 'LaTex'); 
xlabel('Number of datapoints', 'Interpreter', 'LaTex'); 
ylabel('Number of support vectors', 'Interpreter', 'LaTex') 

subplot(1,2,2);
boundedline(nb_samples, mean(sv_rvr,1), std(sv_rvr, 0, 1), 'r', 'transparency', 0.1, 'alpha');
axis([0 inf 0 inf]); 
title('RVR Sparsity (mean $\pm$ std)', 'Interpreter', 'LaTex'); 
xlabel('Number of datapoints', 'Interpreter', 'LaTex'); 
ylabel('Number of relevance vectors', 'Interpreter', 'LaTex') 
