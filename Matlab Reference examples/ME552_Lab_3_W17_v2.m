%% ME 552 Lab 3 MILD Flame Image Processing
% script loads flame images, subtracts the burner flame, time averages the
% flames, crops the image, axisymmetrizes the the left and right halves of
% the flame, and applies a 2D median filter on images. The apparent flame
% area is then determined by performing and Abel inversion on the center of
% the flame along the z-axis (vertical) to find the maximum intensity of
% the flame. Lines from this point are drawn to the flame anchor points and
% rotated around the center vertical axis to calculate the cone surface
% area/apparent area.
% Images are outputed and data is saved to a csv file.

%% Init
clear
clc
close all
format compact


%% Add path to functions for calculating laminar and turbulent flame speeds.
addpath(genpath('abel_inversion'));
bg_path = {'Re5000.tiff','Re10000.tiff'};                         %Background File Path
Cal_path_bg = 'calibration_bg.tiff';              %Calibration File Path
Cal_path_fg = 'calibration_fg.tiff';              %Calibration File Path

numsamples = 1;                                    %Number of sample's
numframes = 360*numsamples;                        %Set number of frames from camera settings
home = pwd;                                        %Sets variable "home" to current directory Callable

fg_path = {'A2_5k_HTI_01.tiff' 'A2_5k_LTI_01.tiff' 'A2_10k_HTI_01.tiff' 'A2_10k_LTI_01.tiff' };   %Forground File Path - This is your image of interest
fg_bg = [1 1 1 1 1 1 2 2 2 2 2 2];

%% Find points of interest
imgCal = imadjust(imread(Cal_path_bg));
imshow(imgCal);
disp('1) left-burner top');
disp('2) right-burner top');
disp('3) 60 cm mark');
disp('4) 65 cm mark');
[xbg_cal,ybg_cal] = ginput(4);

imgCal = imadjust(imread(Cal_path_fg));
imshow(imgCal);
disp('5) left-burner top');
disp('6) right-burner top');
disp('7) 60 cm mark');
disp('8) 65 cm mark');
[xfg_cal,yfg_cal] = ginput(4);

imgFG = imadjust(imread(char(fg_path(1))));
imshow(imgFG);
disp('9) Top of Burner');
disp('10) Top of Flame');
disp('11) Left Flame anchor');
disp('12) Right Flame anchor');
[xfg,yfg] = ginput(4);

%% Image Parameters - Selected From Image
%Use imread, imshow, and ginput functions to complete calibration
%You will need to calibrate to the burner width, the outlet plane of the
%burner, the top of the image, and the number of pixels per unit length 
%(mm or in)
%This will be used for image croping and spatial calibration

Lcrop_bg                   = xbg_cal(1);                                               % left edge of the Burner
Rcrop_bg                   = xbg_cal(2);                                               % right edge of the Burner
Lcrop_fg                   = xfg_cal(1);                                               % left edge of the Burner
Rcrop_fg                   = xfg_cal(2);                                               % right edge of the Burner

Tcrop                      = yfg(2);                                                   % location for cropping of the top of the image
Bcrop                      = yfg(1);                                                   % location for cropping bottom of the image

Left_bg                    = xbg_cal(3);                                               % location of left line on calibration device
Right_bg                   = xbg_cal(4);                                               % location of right line on calibration device
Left_fg                    = xfg_cal(3);                                               % location of left line on calibration device
Right_fg                   = xfg_cal(4);                                               % location of right line on calibration device

%% Image Parameters - User Selected
%calibration determination
Cal_Length                 = 50;  %[mm]                                             % Calibration Unit Length
pixels_bg                  = Right_bg - Left_bg;                                % # of Pixels
pixels_fg                  = Right_fg - Left_fg;                                % # of Pixels
Calibration_bg             = Cal_Length/pixels_bg;                              % mm/pixel
Calibration_fg             = Cal_Length/pixels_fg;                              % mm/pixel

%% Image Read In, Average, and Background Subtract
%read on .tiff, average images in multipage format for backgrounds
%subtract background from images in foreground
%average result

%Load and average pilot flame images 
for j = 1:length(bg_path)
    str_path = char(bg_path(j));
    bg = imfinfo(str_path);
    num_images = numel(bg);
    for k = 1:num_images
        A = imread(str_path, k, 'Info', bg);
        dblA = im2double(A);
        if k ==1 
            average_bg(j,:,:) = dblA;
        else
            average_bg(j,:,:) = average_bg(j) + dblA;
        end
    end
    average_bg(j,:,:) = average_bg(j,:,:)/k;
end
disp('background averaged');

%perform loop to cycle through all the images
for j = 1:length(fg_path)
    %load and average flame image while subtracting burner flame
    str_path = char(fg_path(j));
    fg = imfinfo(str_path);
    num_images = numel(fg);
    avgbg = squeeze(average_bg(fg_bg(j),:,:));
    for k = 1:num_images
        A = imread(str_path, k, 'Info', fg);
        dblA = im2double(A);
        dblA_neg = dblA - avgbg;
        if k ==1 
            average_flame = dblA_neg;
        else
            average_flame = average_flame + dblA_neg;
        end
        
        %Use five consective images
        if k < 6
            flames(j,k,:,:) = dblA_neg;
        end
    end

    %average flames
    average_flame = average_flame/k;
    disp(['Flame image: ' num2str(j) ' averaged']);
    flames(j,6,:,:) = average_flame;
    
    for k = 1:6
        flame = squeeze(flames(j,k,:,:));
        %% Image crop dimensions
        %Crop image based on previously defined values
        cropped_Flame = imcrop(flame, [Lcrop_fg Tcrop (Rcrop_fg - Lcrop_fg) (Bcrop- Tcrop)]);   % Cropped Flame Image

        %% Axisymmetrize the image by averaging both sides
        Axisym = 0.5*(cropped_Flame(:, 1:end) + cropped_Flame(:, end + 1 - (1:end)));   % Use this equation to correct for asymetry
        [f, g] = size(Axisym(:, :));                                                    % get dimensions of the axisymmetrized image

        %% Perform 2D median filter on images
        ImageFilt(:, :) = medfilt2(Axisym); 

        %% Perform Abel inversion 
        %Find the largest intensity of data by sending the function the vertical
        %center of the image from the the line of symmetry. 
        [m,n] = size(ImageFilt);
        [ f_rec , X ] = abel_inversion(ImageFilt(:,floor(n/2)),m,15,0,0);
        iy=find(f_rec==max(f_rec(1:end - 25)));

        %% Plot and save resultant image
        imshow(imadjust(ImageFilt));
        hold on; % Prevent image from being blown away.
        plot(n/2,iy,'k.', 'MarkerSize', 20);

        %generate lines from flame brush

        %have top point (n/2, iy) and bottom points left(xfg(3),yfg(3)),
        %right(xfg(4), yfg(4)
        plot([xfg(3)-Lcrop_fg,n/2,xfg(4)-Lcrop_fg],[m,iy,m],'k', 'LineWidth',2);
        hold off
        
        disp(['Saving image: ' num2str(k) ' of 6']);
        str_img = ['processed_images\' str_path(1:end-5) '_',num2str(k),'.png'];
        saveas(gcf,str_img);

        %% Determine apparent area
        %use calibration to find the height and radius of the cone
        %$$A=\pi*r(r+sqrt(h^2+r^2))$$

        radi_mm(j,k) = (Lcrop_bg + n/2 - xfg(3)) * Calibration_bg; %[mm]
        heights_mm(j,k) = (m - iy) * Calibration_bg; %[mm]
        areas_mm2(j,k) = pi * radi_mm(j,k) * (radi_mm(j,k)+sqrt(heights_mm(j,k)^2+radi_mm(j,k)^2)); %[mm^2]
    end
    
    %% Output Values
    radius_mm = radi_mm(j,:)';
    height_mm = heights_mm(j,:)';
    area_mm2 = areas_mm2(j,:)';
    str_flame = char(fg_path(j));
    str_flame = str_flame(1:end-5);

    output = table(height_mm,radius_mm,area_mm2);
    writetable(output,['output_', str_flame,'.csv']);
end

