%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% MEAN SHIFT TRACKING
% ----------------------
% YOU HAVE TO MODIFY THIS FILE TO MAKE IT RUN!
% YOU CAN ADD ANY FUNCTION YOU FIND USEFUL!
% In particular, you have to create the different functions:
%	- cd = color_distribution(imagePatch, m)
%	- k = compute_bhattacharyya_coefficient(p,q)
%	- weights = compute_weights(imPatch, qTarget, pCurrent, Nbins)
% 	- z = compute_meanshift_vector(imPatch, prev_center, weights)
%
% the function to extract an image part is given.
% ----------------
% Authors: D. SIdib�
% Date: October 19th, 2011
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clc
clear all
close all

%% read images
imPath = 'car'; imExt = 'jpg';

%%%%% LOAD THE IMAGES
%=======================
% check if directory and files exist
if isdir(imPath) == 0
    error('USER ERROR : The image directory does not exist');
end

filearray = dir([imPath filesep '*.' imExt]); % get all files in the directory
NumImages = size(filearray,1); % get the number of images
if NumImages < 0
    error('No image in the directory');
end

disp('Loading image files from the video sequence, please be patient...');
% Get image parameters
imgname = [imPath filesep filearray(1).name]; % get image name
I = imread(imgname);
VIDEO_WIDTH = size(I,2);
VIDEO_HEIGHT = size(I,1);

ImSeq = zeros(VIDEO_HEIGHT, VIDEO_WIDTH, NumImages);
for i=1:NumImages
    imgname = [imPath filesep filearray(i).name]; % get image name
    ImSeq(:,:,i) = imread(imgname); % load image
end
disp(' ... OK!');


%%%%% INITIALIZE THE TRACKER
%=======================

% HERE YOU HAVE TO INITIALIZE YOUR TRACKER WITH THE POSITION OF THE OBJECT IN THE FIRST FRAME

% You can use Background subtraction or a manual initialization!
% For manual initialization use the function imcrop
[patch, rect] = imcrop(ImSeq(:,:,1)./255);


% DEFINE A BOUNDING BOX AROUND THE OBTAINED REGION : this gives the initial state

% Get ROI Parameters
rect = round(rect);
ROI_Center = round([rect(1)+rect(3)/2, rect(2)+rect(4)/2]); 
ROI_Width = rect(3);
ROI_Height = rect(4);

% you can draw the bounding box and show it on the image


%% MEANSHIFT TRACKING
%=======================

%% FIRST, YOU NEED TO DEFINE THE COLOR MODEL OF THE OBJECT

% compute target object color probability distribution given the center and size of the ROI
imPatch = extract_image_patch_center_size(ImSeq(:,:,1), ROI_Center, ROI_Width, ROI_Height);

% color distribution in RGB color space
Nbins = 8;
TargetModel = color_distribution(imPatch, Nbins);


% Mean-Shift Algorithm 
prev_center = ROI_Center; % set the location to the previous one 
figure;
for n = 2:NumImages

    % get next frame
    I = ImSeq(:,:,n);
    while(1)
    	% STEP 1
    	% calculate the pdf of the previous position
    	imPatch = extract_image_patch_center_size(I, prev_center, ROI_Width, ROI_Height);
    	ColorModel = color_distribution(imPatch, Nbins);
    
    	% evaluate the Bhattacharyya coefficient
     	rho_0 = compute_bhattacharyya_coefficient(TargetModel, ColorModel);
    
    	% STEP 2
    	% derive the weights
    	weights = compute_weights(imPatch, TargetModel, ColorModel, Nbins);
    
    	% STEP 3
    	% compute the mean-shift vector
    	% using Epanechnikov kernel, it reduces to a weighted average
        z = compute_meanshift_vector(imPatch, weights);
    
    	new_center = z;

    	% STEP 4, 5
        %% STEP 4 and 5 should be here !!
        % calculate the pdf of new position
        
        while(1)
            newPatch = extract_image_patch_center_size(I, new_center, ROI_Width, ROI_Height);
            newModel = color_distribution(newPatch, Nbins);
        
            % evaluate the Bhattacharyya coefficient with new model
            rho_1 = compute_bhattacharyya_coefficient(TargetModel, newModel);
            
            if rho_1 < rho_0
                new_center = (prev_center + new_center)*0.5;
            else
                break
            end
            
                        
        end
        % STEP 6
    	if norm(new_center-prev_center, 1) < 0.005
       		break
    	end
    	prev_center = new_center;

    end

    % Show your tracking results 
    imshow(I, []);
    hold on;
    rectangle('Position',[new_center(1)-ROI_Width/2, new_center(2)-ROI_Height/2, ROI_Width, ROI_Height], 'EdgeColor','g','LineWidth',1 );
    hold off;
    pause(0.01);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% THE DIFFERENT FUNCTIONS TO BE USED
% ======================================


