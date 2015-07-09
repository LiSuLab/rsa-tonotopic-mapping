% CW 2015-06
function [feature_paths] = label_with_features(glm_paths, M, FEATURES, lagSTCMetadatas, userOptions)
    
    import rsa.*
    import rsa.meg.*
    import rsa.rdm.*
    import rsa.util.*
    
    for chi = 'LR'
        
        prints('Loading GLM mesh for %sh...', lower(chi));
        
        glm_mesh_betas = directLoad(glm_paths.betas.(chi));
        
        % Trim the all-1s predictor.
        glm_mesh_betas = glm_mesh_betas(:, :, 2:end);
        
        [n_vertices, n_timepoints, n_betas] = size(glm_mesh_betas);
        
        %% Label and threshold
        
        prints('Labelling and thresholding with feature models...');
        
        for f = 1:numel(FEATURES)
            
            feature_name = FEATURES{f};
            feature_template = M(f, :);
        
            % Preallocate
            feature_map = zeros(n_vertices, n_timepoints);

            for t = 1:n_timepoints
                for v = 1:n_vertices

                    beta_profile = squeeze(glm_mesh_betas(v, t, :));
                    feature_match = beta_profile .* feature_template';

                    feature_map(v, t) = ( ...
                        sum(feature_match));
                end
            end
            
            feature_paths.(feature_name).(chi) = fullfile(userOptions.rootPath, 'Meshes', sprintf('feature-%s-%sh.stc', lower(feature_name), lower(chi)));
            
            write_stc_file( ...
                lagSTCMetadatas.(chi), ...
                feature_map, ...
                feature_paths.(feature_name).(chi));
                
        end%for:features
        
    end%for:chi

end%function
