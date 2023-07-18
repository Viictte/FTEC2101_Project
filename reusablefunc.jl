using CSV, Glob, DataFrames
using Statistics

function performance_testdata( path_to_test, x, t,oldbar_R )
    files = glob( "*_test.csv", path_to_test );
    dfs = DataFrame.( CSV.File.( files ) ); 
    T = t; n = length(dfs);
    stocks_retur = zeros(T,n);
    for i = 1:n
        # compute the realized return R_i(t)
        stocks_retur[:,i] = (dfs[i].Close-dfs[i].Open) ./ dfs[i].Open;
    end
    names_stocks = [ dfs[i].Name[1] for i in 1:n ];
    # calculate r_i and Sigma
    bar_R = [ mean( stocks_retur[:,i] ) for i in 1:n ];
    Sigma = [ mean( (stocks_retur[:,i].-bar_R[i]).*(stocks_retur[:,j].-bar_R[j]) ) for i=1:n, j=1:n ]; 
    # calculate Sharpe Ratio
    portfolio = x;
    if sum( portfolio ) < 1e-10
        sharpe_ratio = 0;
    else
        sharpe_ratio = sum( bar_R.* portfolio ) / sqrt(portfolio'*Sigma*portfolio);
    end
    cost = sum( x );
    downsiderisk = float([0 0]);
    for i = 1:T
        if sum(x.*(oldbar_R-stocks_retur[i,:])) > 0
            downsiderisk[1] = downsiderisk[1] + 1;
            downsiderisk[2] = downsiderisk[2] + sum(x.*(oldbar_R-stocks_retur[i,:]));
        else
            downsiderisk[1] = downsiderisk[1] + 0; 
            downsiderisk[2] = downsiderisk[2] + 0;
        end
    end
    downsiderisk[1] = downsiderisk[1]/T;
    downsiderisk[2] = downsiderisk[2]/T;
    print("Sharpe Ratio = ", sharpe_ratio, ", Prob. of Downside Risk Violation = ", downsiderisk[1],", Amt. of Downside Risk Violation = ", downsiderisk[2], ", Return = ", sum(bar_R.*portfolio), ", Portfo Value = ", cost );
    return sharpe_ratio
end

function downsiderisk( x, T, stocks_retur,barR )
    downsiderisk = float([0 0]);
    for i = 1:T
        if sum(x.*(barR-stocks_retur[i,:])) > 0
            downsiderisk[1] = downsiderisk[1] + 1;
            downsiderisk[2] = downsiderisk[2] + sum(x.*(barR-stocks_retur[i,:]));
        else
            downsiderisk[1] = downsiderisk[1] + 0; 
            downsiderisk[2] = downsiderisk[2] + 0;
        end
    end
    downsiderisk[1] = downsiderisk[1]/T;
    downsiderisk[2] = downsiderisk[2]/T; 
    print( "Prob. of Downside Risk Violation = ", downsiderisk[1],", Amt. of Downside Risk Violation = ", downsiderisk[2] );
    return downsiderisk
end

function total_performance( path_to_test, x, t1,t2)
    portfolio = x;
    cost = sum( x );
    
    #For training data
    files = glob( "*_train.csv", path_to_test );
    dfs = DataFrame.( CSV.File.( files ) ); 
    T1 = t1; n = length(dfs);
    stocks_retur_train = zeros(T1,n);
    for i = 1:n
        # compute the realized return R_i(t)
        stocks_retur_train[:,i] = (dfs[i].Close-dfs[i].Open) ./ dfs[i].Open;
    end
    names_stocks = [ dfs[i].Name[1] for i in 1:n ];
    # calculate r_i and Sigma
    bar_R_train = [ mean( stocks_retur_train[:,i] ) for i in 1:n ];
    Sigma_train = [ mean( (stocks_retur_train[:,i].-bar_R_train[i]).*(stocks_retur_train[:,j].-bar_R_train[j]) ) for i=1:n, j=1:n ]; 
    #calculate downsiderisk 
    traindownsiderisk = float([0 0]);
    for i = 1:T1
        if sum(x.*(bar_R_train-stocks_retur_train[i,:])) > 0
            traindownsiderisk[1] = traindownsiderisk[1] + 1;
            traindownsiderisk[2] = traindownsiderisk[2] + sum(x.*(bar_R_train-stocks_retur_train[i,:]));
        else
            traindownsiderisk[1] = traindownsiderisk[1] + 0; 
            traindownsiderisk[2] = traindownsiderisk[2] + 0;
        end
    end
    traindownsiderisk[1] = traindownsiderisk[1]/T1;
    traindownsiderisk[2] = traindownsiderisk[2]/T1;
    
    #for test data
    files = glob( "*_test.csv", path_to_test );
    dfs = DataFrame.( CSV.File.( files ) ); 
    T2 = t2; n = length(dfs);
    stocks_retur_test = zeros(T2,n);
    for i = 1:n
        # compute the realized return R_i(t)
        stocks_retur_test[:,i] = (dfs[i].Close-dfs[i].Open) ./ dfs[i].Open;
    end
    names_stocks = [ dfs[i].Name[1] for i in 1:n ];
    # calculate r_i and Sigma
    bar_R_test = [ mean( stocks_retur_test[:,i] ) for i in 1:n ];
    Sigma_test = [ mean( (stocks_retur_test[:,i].-bar_R_test[i]).*(stocks_retur_test[:,j].-bar_R_test[j]) ) for i=1:n, j=1:n ]; 
    
    # calculate Sharpe Ratio
    if sum( portfolio ) < 1e-10
        sharpe_ratio = 0;
    else
        sharpe_ratio = sum( bar_R_test.* portfolio ) / sqrt(portfolio'*Sigma_test*portfolio);
    end
    
    testdownsiderisk = float([0 0]);
    for i = 1:T2
        if sum(x.*(bar_R_train-stocks_retur_test[i,:])) > 0
            testdownsiderisk[1] = testdownsiderisk[1] + 1;
            testdownsiderisk[2] = testdownsiderisk[2] + sum(x.*(bar_R_train-stocks_retur_test[i,:]));
        else
            testdownsiderisk[1] = testdownsiderisk[1] + 0; 
            testdownsiderisk[2] = testdownsiderisk[2] + 0;
        end
    end
    testdownsiderisk[1] = testdownsiderisk[1]/T2;
    testdownsiderisk[2] = testdownsiderisk[2]/T2;     

    print("Sharpe Ratio = ", sharpe_ratio, ", Prob. of Downside Risk Violation (training data) = ", traindownsiderisk[1],", Amt. of Downside Risk Violation (training data) = ", traindownsiderisk[2],", Prob. of Downside Risk Violation (testing data) = ", testdownsiderisk[1],", Amt. of Downside Risk Violation (testing data) = ", testdownsiderisk[2] );
    return sharpe_ratio    
        

end
