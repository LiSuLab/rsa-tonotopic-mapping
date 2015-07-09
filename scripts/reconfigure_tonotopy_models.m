function models_out = reconfigure_tonotopy_models(models_in)
    [n_models, n_timepoints] = size(models_in);
    
    %preallocate
    models_out(1:n_timepoints, 1:n_models) = struct('RDM', NaN, 'name', NaN', 'color', NaN);
    
    for m = 1:n_models
        for t = 1:n_timepoints
            models_out(t, m).RDM = models_in{m, t}.RDM;
            models_out(t, m).name = models_in{m, t}.name;
            models_out(t, m).color = models_in{m, t}.color;
        end
    end
end%function
