function detectBeads(spatialFilterKernelSize, spatialThreshold, waterThreshold)
% detectBeads detects beads in beaded rivers in the Arctic for Planet Hack
% 2020.
%
%    Usage:
%         % Average pool width (m)
%         poolWidth = 14;
%         % Resolution of data (m / px)
%         resolution = 3;
%         spatialFilterKernelSize = ceil(poolWidth / resolution);
%         % Spatial threshold value
%         spatialThreshold = 1;
%         % Water threshold value
%         waterThreshold = 0.1;
%
%         % Detect beads within the Arctic Stream
%         detectBeads(spatialFilterKernelSize, spatialThreshold, waterThreshold)
%
%    Inputs:
%        spatialFilterKernelSize - The size of the spatial filter kernel
%                                  (px)
%        spatialThreshold        - The spatial threshold value in water
%                                  index map, where the water index is
%                                  defined as: index = (g - nIR) / (g + nIR)
%        waterThreshold          - The water index threshold value in the
%                                  water index map, where the water index
%                                  is defined as: index = (g - nIR) / (g + nIR)
%    Outputs:
%        NONE
%
%
% Author: Kevin Lacaille

    % Set inputs, if not given
    if nargin == 0
        % Average pool width (m)
        poolWidth = 14;
        % Resolution of data (m / px)
        resolution = 3;
        % Spatial filter kernel size (px)
        spatialFilterKernelSize = 5;%ceil(poolWidth / resolution);
        % Spatial threshold value
        spatialThreshold = 1;
        % Water threshold value
        waterThreshold = 0.1;
    end

    for ii = 1:8
        % Import data
    %     waterIndexMap = imread("Planet_MNDWI.tif");
        waterIndexMap = imread("Beaded_" + ii + ".tif");


    %     % Select only part of data where data exists
    %     % OG
    %     waterIndexMap = waterIndexMap(180:510, 940:1280);
    %     % 1
    %     waterIndexMap = waterIndexMap(170:485, 1:end);
    %     % 2
    %     waterIndexMap = waterIndexMap(15:527, 184:680);

    %     % Spatially filter data
    %     spatiallyFilteredData = differenceOfGaussians(waterIndex, spatialFilterKernelSize);

        % Detect beads
        detectionStruct = getDetections(waterIndexMap, spatialFilterKernelSize, spatialThreshold, waterThreshold);

        % Visualize data
        visualizeData(waterIndexMap, detectionStruct, poolWidth, resolution, ii);
    end
    
end

function spatiallyFilteredData = differenceOfGaussians(inputData, spatialFilterKernelSize)
% differenceOfGaussians generates a spatially filtered image by taking the
% difference of Gaussians.
%
%    Inputs:
%        inputData               - The input image.
%        spatialFilterKernelSize - The size of the spatial filter kernel
%                                  (px).
%    Outputs:
%        spatiallyFilteredData   - The spatially filtered image.


        % Generate Gaussian filters
        largeGaussianFilter = imgaussfilt(inputData, spatialFilterKernelSize / 4);
        smallGaussianFilter = imgaussfilt(inputData, spatialFilterKernelSize);

        % Measure the difference of Gaussian filters
        spatiallyFilteredData = largeGaussianFilter - smallGaussianFilter;

end

function detectionStruct = getDetections(inputData, spatialFilterKernelSize, spatialThreshold, waterThreshold)
% getDetections returns detections of beads,
%
%    Inputs:
%        inputData               - The input image.
%        spatialFilterKernelSize - The size of the spatial filter kernel
%                                  (px).
%        spatialThreshold        - The spatial threshold value in water
%                                  index map, where the water index is
%                                  defined as: index = (g - nIR) / (g + nIR)
%        waterThreshold          - The water index threshold value in the
%                                  water index map, where the water index
%                                  is defined as: index = (g - nIR) / (g + nIR)
%    Outputs:
%        detectionStruct         - A struct of detections of the form:
%                                  Area, Centroid, BoundingBox, MarkerIdx.
%


    % Returns the maximum value in a spatialFilterKernelSize^2 area of the pixel of interest
    dilatedMap = imdilate(inputData, ones(spatialFilterKernelSize));

    % This mask performs non-maximal suppression (NMS) for a spatialFilterKernelSize^2 area in the dilation map
    nmsMaskDilate = inputData == dilatedMap;
    % A mask that returns the maximums and minimums in spatialFilterKernelSize^2 areas
    nmsMask = nmsMaskDilate;

    % Kernal size to preform statistical measures (for mean & std maps)
    maskingKernal = 3 * spatialFilterKernelSize;
    % Sliding window mean mask
    meanMap = imboxfilt(inputData, maskingKernal);
    % Sliding window standard deviation mask
    stdMap = stdfilt(inputData, true(maskingKernal));
    % Threshold anything greater than threshold x standard deviations above the mean
    % The absolute value is used to include occlusions
    processedMeanDiff = abs((inputData - meanMap));
    processedMeanDiff(processedMeanDiff < waterThreshold) = 0;
    threshMask = processedMeanDiff > (spatialThreshold * stdMap);

% %     imagesc(imfuse(inputData, threshMask, 'blend', 0.5))

    % Only return hits that survive NMS and thresholding
    outputMask = nmsMask & threshMask;
    % Output mask convolved with filter size for detections
    outputMaskConvolved = logical(conv2(outputMask, ones(spatialFilterKernelSize), 'same'));

    % Struct containing detections (area, centroid, bounding box)
    detectionStruct = regionprops(outputMaskConvolved);
    nanArray = num2cell(nan * ones(length(detectionStruct), 1));
    [detectionStruct(1:end).MarkerIdx] = nanArray{:};

end

function visualizeData(inputData, detectionStruct, poolWidth, resolution, ii)
% visualizeData visualizes the data and detections of beaded streams.
%
%    Inputs:
%        inputData               - The input image.
%        detections              - The detections.
%        spatialFilterKernelSize - The 
%
%    Outputs:
%        NONE
%


%     % Visualize data
%     figure(1)
%     imagesc(inputData);
%     hold on
%     title("Normalized difference")
%     hold off

    % Visualize detections
    figure(ii)
    ims = imagesc(inputData, [-0.8, -0.3]);
    hold on
    set(gca, 'xtick', [])
    set(gca, 'xticklabel', [])
    set(gca, 'ytick', [])
    set(gca, 'yticklabel', [])


    nBeads = 0;
    % Draw boxes around all detections
    for jj = 1:numel(detectionStruct)
        % 
        if detectionStruct(jj).Area * resolution > poolWidth^2
            colour = 'black';
        else
            colour = 'red';
            nBeads = nBeads + 1;
        end
        
        drawrectangle(ims.Parent, 'Position', ...
            [detectionStruct(jj).Centroid(1) - detectionStruct(jj).BoundingBox(3) / 2, ...
             detectionStruct(jj).Centroid(2) - detectionStruct(jj).BoundingBox(4) / 2, ...
             detectionStruct(jj).BoundingBox(3), detectionStruct(jj).BoundingBox(4)], ...
            'Interactions','none', 'Color', colour, 'FaceAlpha', 0, 'LineWidth', 1);

    end
    title(sprintf("Number of beads detected: %i", nBeads))
    hold off
    
    saveas(gcf, "Beaded_withdets_" +ii + ".png")
    
end
