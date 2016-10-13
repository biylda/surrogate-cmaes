classdef DTFileStatistics < Observer
%SCREENSTATISTICS -- log statistics from DoubleTrainEC into the file
  properties
    verbosity
    datapath
    exp_id
    instance
    expFileID
    file
  end

  methods
    function obj = DTFileStatistics(params)
      obj@Observer();
      obj.verbosity = defopts(params, 'verbose', 5);
      obj.datapath  = defopts(params, 'datapath', '/tmp');
      obj.exp_id    = defopts(params, 'exp_id', datestr(now,'yyyy-mm-dd_HHMMSS'));
      obj.instance  = defopts(params, 'instance', NaN);
      obj.expFileID = defopts(params, 'expFileID', '');
      obj.file  = [obj.datapath filesep obj.exp_id '_log_' obj.expFileID '.dat'];
    end

    % get the interesting data from DoubleTraineEC and process them
    function notify(obj, ec, varargin)
      fid = fopen(obj.file, 'a');
      % write header
      if (ec.cmaesState.countiter == 1 && ec.counteval <= (ec.cmaesState.lambda+1))
        % only in the first iteration when counteval is very low
        % (do not write header after CMA-ES restarts)
        func_dim_id = strsplit(obj.expFileID, '_');
        fprintf(fid, '#  f%s  dim: %s  instance: %d  date: %s\n', ...
            func_dim_id{1}, func_dim_id{2}, ...
            obj.instance, datestr(now, 'yyyy-mm-dd HH:MM:SS'));
        fprintf(fid, '#  iter  totEvals  orEvalsPop  Dopt  rmseReeval  rnkReeval  rnk2Models rnkValid  modelTypeUsed  nTrainData  nDataInRange  modelAge  sigmaPow2  rmseOldModel  rnkOldModel  ageOldModel  diagD_max  diagD_min  diagD_ratio  %s\n', sprintf('diagD_%02d ', 1:length(ec.cmaesState.diagD)));
      end

      % prepare model-related data for output
      model = 0;        % i.e. no model was trained
      nTrainData = 0;
      if (~isempty(ec.model) && ec.model.isTrained() ...
          && ec.model.trainGeneration == ec.cmaesState.countiter)
        % the first model was successfully trained
        model = 1; nTrainData = ec.model.getTrainsetSize();
      end
      if (~isempty(ec.retrainedModel) && ec.retrainedModel.isTrained() ...
          && ec.retrainedModel.trainGeneration == ec.cmaesState.countiter)
        % the second model was successfully trained
        model = 2; nTrainData = ec.retrainedModel.getTrainsetSize();
      end

      %            iter  tot orEvl Dopt rmseR  rnkR  rnk2 rnkV mType nDa nDiR  mAg sig^2 rmsO rnkO ageO mxDi miDi  Drio  D_1,...,D_n
      fprintf(fid, '%4d  %5d  %2d  %.4e  %.2e  %.2f  %.2f  %.2f  %d  %2d  %2d  %d  %.2e  %.2e  %.2f  %d  %.2e  %.2e  %.2e  %s\n', ...
          ec.cmaesState.countiter, ec.counteval, sum(ec.pop.origEvaled), ...
          ec.stats.fmin - ec.surrogateOpts.fopt, ...
          ec.stats.rmseReeval, ...
          ec.stats.rankErrReeval, ...
          ec.stats.rankErr2Models, ...
          ec.stats.rankErrValid, ...
          model, nTrainData, ec.stats.nDataInRange, ec.modelAge, ...
          ec.cmaesState.sigma^2, ...
          ec.stats.rmseOldModel, ...
          ec.stats.rankErrOldModel, ...
          ec.stats.ageOldModel, ...
          max(ec.cmaesState.diagD), ...
          min(ec.cmaesState.diagD), ...
          max(ec.cmaesState.diagD)/min(ec.cmaesState.diagD), ...
          sprintf('%.2e ', sort(ec.cmaesState.diagD, 1, 'descend')) ...
          );
      fclose(fid);
    end
  end
end
