clc
clear
close all

%% script to calculate area and number of holes in seran wrap

%% Set  calibration
% this will be done once per picture set
% as instructed, set crop and scale calibration for photo
% set

cd ..\Photos\Test   %modify for folder of interest
contents = dir('*.jpg');

filename = contents(1).name;


img = imread(filename); %make this first file of photos
imshow(img)


disp('click on:');
disp('1) TL 30cm mark');
disp('2) TR 60 cm mark');
disp('3) BR 60cm mark');

disp('4) TL of image');
disp('5) BR of image');


[x_cal,y_cal] = ginput(5);

Cal_AREA = 300;  %[mm^2]                                        % Calibration Unit Length
Cal_pixels = (x_cal(2)-x_cal(1))*(y_cal(3)-y_cal(2));
Cal_scale  = Cal_AREA/Cal_pixels;                              % mm^2/pixel



%% image processing

%to process the image we will  resize the image, then equalize the
%histogram to prodive stronger contrast. Once this is complete convert to
%grayscale, then convert to Bianary with adaptive or global thresholding.


for i = 1:numel(contents)
    
    %read in image
    imgname = contents(i).name;
    img = imread(imgname);
    
    %Crop image
    img = img(y_cal(4):y_cal(5),x_cal(4):x_cal(5),:);
    
    %resize image
      img = imresize(img,.3);
    
    %convert image to grayscale
    imgGs = rgb2gray(img);
    
    % Equalize histogram for sufficient contrast
    histOriginal = imhist(imgGs);
    imgGsEq = histeq(imgGs);
    
    %display images
%     imshow(imgGs),title('original')
%     figure, imshow(imgGsEq),title('adjsuted')
    
    %display hists
%     figure, imhist(imgGs) ,title('original')
%     figure,imhist(imgGsEq) ,title('adjsuted')
    
    % sutract background from image to elimitate uneven background illumination
    %https://www.mathworks.com/help/images/image-enhancement-and-analysis.html
    
    
    
    %binarize grayscale image
    
     imgGs = imcomplement(imgGs) ;  %this inverts image if needed. delete if not needed.
    %
    %         %method one ADAPTIVE
    %     imgBiAdaptive = imbinarize(imgGs,'adaptive','Sensitivity',0.5);       %sensitivity is .5 by default; %'ForegroundPolarity','dark'
    %     figure
    %     imshowpair(imgGsEq,imgBiAdaptive,'montage'), title ('adaptive');
    %
    %method 2, global
    %invert image
    imgBiGlobal = imbinarize(imgGs,'global') ;% threshold can be changed with graythresh function
    figure
    imshowpair(imgGs,imgBiGlobal,'montage'), title ('global');
    
    %display the changes
    
    
    
    
    %% image calculations
    
    %object anaysis
    %https://www.mathworks.com/help/images/object-analysis.html
    
    stats = regionprops(imgBiGlobal,'area');
    
    [B,L] = bwboundaries(imgBiGlobal,'noholes');
    imshow(label2rgb(L,@jet,[.5 .5 .5]))
    hold on
    for k = 1:length(B)
        boundary = B{k};
        plot(boundary(:,2),boundary(:,1),'w','lineWidth',2)
    end
    
    
end
%region properties
%https://www.mathworks.com/help/images/pixel-values-and-image-statistics.html





