clc,clear
%% Reading and calculation of basic parameters
% parallel.gpu.enableCUDAForwardCompatibility(true);
tic
objDir = ''; %GT's path
objFlist = dir(sprintf('%s/*.png',objDir));
imgDir = ''; % path to save the simulated results
psf_dir = ''; %PSF's path
% psfFlist = dir(sprintf('%s/*.png',psf_dir));

num = length(objFlist);
% ringnum = length(psfFlist); %ring num
ringnum = 7;
psf_px = 1; %pixelsize of psf, um.
img_px = 3; %pixelsize of sensor(image),um
scale = img_px/psf_px; %scale to resize obj
known_FOV = [0,5,11,16,22,27,32.5]/180*pi; %incident angel
% known_psf = [124,477,987,1493,1991]; % y coordinate of uncutted PSF
examplename = objFlist.name;
example = imread([objDir,'\',examplename]);
example_re = imresize(example,scale);
[m,n,~] = size(example_re); 
bit = 16;

PSF = cell(1,ringnum);
%read PSF from MAT(from txt)
for i=1:ringnum
    PSF{i} = cell2mat(struct2cell(load([psf_dir,'\PSF_FOV',num2str(i)])));
end

% % %read PSF from pictures
% for i=1:ringnum
%     psf_fname = sprintf('%s/%s',psf_dir,psfFlist(i).name);
% %     PSF{i} = double(imread(psf_fname));
%     psfscale = 0.5;
%     PSF{i} = imresize(double(imread(psf_fname)),psfscale); % downsampled
% end

%energy normalization
for j = 1:ringnum
    PSF_cur = PSF{j};
    for i = 1:3
        PSF_cur(:,:,i) = PSF_cur(:,:,i)/sum(sum(PSF_cur(:,:,i)));
    end
    PSF{j} = PSF_cur;
end

%use GPU
for i = 1:ringnum
    PSF{i}=gpuArray(PSF{i});
end

%%%%%caculate R %%%%%
L = ceil(sqrt(m^2+n^2));
if mod(L,2) ~= 0  %let L always be even
   L=L+1;
end

%if PSF given by incident angles
obj_distance = L/2/tan(known_FOV(ringnum));  %Assuming that the picture fills FOV, get the object distance
R = round(obj_distance*tan(known_FOV));

% %if PSF given by image height
% R = known_FOV/known_FOV(ringnum)*L/2;

% %PSF is given by cutted pictures
% psf_loc = abs(known_psf-known_psf(1)); %PSF location in sensor to measure it
% psf_img_loc = round(psf_loc/psf_loc(ringnum)*(L/2)); % %PSF corresponding location in simulated image
% R = psf_img_loc;

cut_R = zeros(1,ringnum); 
for i=1:ringnum
    if i == ringnum
        cut_R(i)=R(i);
    else
        cut_R(i) = round((R(i)+R(i+1))/2);
    end    
end

%%%%%%convolution%%%%%
for k = 1:num
    disp(k);
    obj_fname = sprintf('%s/%s',objDir,objFlist(k).name);
    obj = single(imread(obj_fname));
    obj = obj/(2^bit-1);
%     obj = obj.^(2.2);
    obj = imresize(obj,scale);
%     figure,imshow(obj);
    
    IMG = zeros(m,n,3);
%    IMG_noise = zeros(m,n,3);
    for i = 1:3         
        obj_rgb = obj(:,:,i);       
        obj_rgb = gpuArray(obj_rgb);
        obj_pad = padarray(obj_rgb,[L/2-ceil(m/2),L/2-ceil(n/2)],'replicate');
        
        obj_conv_gpu = cell(1,ringnum);
        obj_conv = cell(1,ringnum);
        ring = cell(1,ringnum);
        
        g_a = 20*ones(1,ringnum); % the peak of gaussion function
%         g_a(1) = 1.5; % some fine-tunes
        
        img = zeros(L,L);
        for j = 1:ringnum
            PSF_temp = PSF{j};
            obj_conv_gpu{j} = conv2(obj_pad,PSF_temp(:,:,i),'same');
            obj_conv{j} = gather(obj_conv_gpu{j});
            cir_out = circlecutter(obj_conv{j},cut_R(j),g_a(j),0.01);
            if j==1
                ring{j} = cir_out;
            else
                cir_in = circlecutter(obj_conv{j},cut_R(j-1),g_a(j),0.01);
                ring{j}= cir_out - cir_in;
            end
%             figure,imshow(ring{j});
            img = img+ring{j};
        end
        IMG(:,:,i) = img(ceil(L/2-m/2+1):ceil(L/2+m/2),ceil(L/2-n/2+1):ceil(L/2+n/2));
%         IMG_noise(:,:,i) = imnoise(IMG(:,:,i),'gaussian',0,0.01^2);
    end
    IMG = imresize(IMG,1/scale);
    IMG = IMG/max(max(max(obj)));
%     figure,imshow(IMG,[]);
    IMG = uint16(65535*IMG);
    IMG_noise = imnoise(IMG,'gaussian',0,0.005^2);
%   figure,imshow(IMG,[]);
    imgFname = [imgDir,'/',sprintf('BL%04d.png',k)];
    imwrite(IMG_noise,imgFname);
end          
toc