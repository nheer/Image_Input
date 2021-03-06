function [ O ] = LoadEdgeDataFun(I,type)
    %This function takes an input structure where the fields include the
    %following information:
        %timestep: self explanatory (in seconds)
        %xy: the xy pixel resolution, should be the same as was provided to Edge
        %z: z resolution (currently not used -- JSC 5/9/14)
        %zslice: the slice number to keep (just the number, i.e. "5", not "z005"
        %Filename: 'Image1_011113'. Don't include slashes or file suffix
        %memchannel: which number channel. Don't include _c00
        %signalchannel1: same, but for Rok or Myosin channel
        %Root: File directory up to 'DATA_GUI/', e.g.
             %'/Users/jcoravos/Documents/MATLAB/EDGE-1.06/DATA_GUI/'.
             %Everything following ~/DATA_GUI/' is provided in the script
             
        %type is either 1 if the image is a still, or 2 if the image is a
        %movie.
        
       
%% Extracting Image-specific Data from InputStruct
conv_fact = (1/I.z); % pixels/micron -- conversion factor for changing microns to pixels
if I.zslice < 10
    zkeep = strcat('_z00',num2str(I.zslice)); %zslice to keep
else 
    zkeep = strcat('_z0',num2str(I.zlice));
end

memchannel = strcat('_c00',num2str(I.memchannel));
signalchannel1 = strcat('_c00',num2str(I.signalchannel1)); %Rok (or other signal) channel
if isfield(I,'signalchannel2') == 1
    signalchannel2 = strcat('_c00',num2str(I.signalchannel2)); %a second channel (only if you populate this field in LoadEdgeDataConfig)
end
if isfield(I,'signalchannel3') == 1
    signalchannel3 = strcat('_c00',num2str(I.signalchannel3));
end

%% File Names

switch type
    case 1
        term = '';
    case 2
        term - '_t';
end

sig1fileRoot = strcat(I.Root,I.Filename,'/',I.sig1dir,'/',I.sig1dir,term);
sig2fileRoot = strcat(I.Root,I.Filename,'/',I.sig2dir,'/',I.sig2dir,term);
sig3fileRoot = strcat(I.Root,I.Filename,'/',I.sig3dir,'/',I.sig3dir,term);
membraneRoot = strcat(I.Root,I.Filename,'/Membranes/Raw/', I.memdir,term) ;%make this the file used for Edge membrane segmentation
measdir = strcat(I.Root,I.Filename,'/Measurements/');
    measCenty = 'Membranes--basic_2d--Centroid-y.mat';
    measCentx = 'Membranes--basic_2d--Centroid-x.mat';
    measVerty = 'Membranes--vertices--Vertex-y.mat';
    measVertx = 'Membranes--vertices--Vertex-x.mat';
    measArea =  'Membranes--basic_2d--Area.mat';
    measPerim = 'Membranes--basic_2d--Perimeter.mat';
    myoInt = 'Myosin--myosin_intensity--Myosin intensity.mat';
    
    
%% Load Measurements
    % this section extracts a single slice (specified by the y coordinate in .data(...).
    % the x coordinate is the cell index, and the y coordinate is time step.
    
    slice = I.edgedslice; %IMPORTANT. This specifies that the appropriate slice of data is drawn from the Edge data set.
    
Centy = load(strcat(measdir,measCenty));  
Centx = load(strcat(measdir,measCentx)); 
Verty = load(strcat(measdir,measVerty));  
Vertx = load(strcat(measdir,measVertx));      
Area = load(strcat(measdir,measArea));        
Perim = load(strcat(measdir,measPerim));   
SigInt = load(strcat(measdir,myoInt));


        O.Centy = squeeze(Centy.data(:,slice ,:));
        O.Centx = squeeze(Centx.data(:,slice,:));
        O.Verty = squeeze(Verty.data(:,slice,:));
        O.Vertx = squeeze(Vertx.data(:,slice,:));
        O.Area = squeeze(cell2mat(Area.data(:,slice,:)));
        O.Perim = squeeze(Perim.data(:,slice,:));
        O.SigInt = squeeze(cell2mat(SigInt.data(:,slice,:)));
        

O.SigInt_areanorm = O.SigInt./O.Area; %generates an area-normalized signal intensity
    
    
%% Determine framenum and cellnum
switch type
    case 1
        O.frame_num = 1
        O.cell_num = length(O.Area)
    case 2
        [frame_num,cell_num] = size(O.Area);
        O.frame_num = frame_num;
        O.cell_num = cell_num;
end
%% Convert from microns to pixels
    % all the above cells are in microns. Multiply each cell by the
    % conversion factor (above) to convert to pixels
    O.Centy_pix = gmultiply(O.Centy,conv_fact);
    O.Centx_pix = gmultiply(O.Centx,conv_fact);
    O.Verty_pix = gmultiply(O.Verty,conv_fact);
    O.Vertx_pix = gmultiply(O.Vertx,conv_fact);
    O.Perim_pix = gmultiply(O.Perim,conv_fact);

%% Load Membrane and Rok movie
    %loads tif image sequences from Edge analysis into time stacks (3d) 
%imread(strcat(membraneRoot,'001_z005_c002.tif'));   %declaring membranestack matrix
%[m,n] = size(ans); %this size is in pixels, not microns
%membranestack = zeros(m,n,frame_num); %x position is frame 
%rokstack = zeros(m,n,frame_num);

switch type
    case 1
        mem_file = strcat(membraneRoot,zkeep,memchannel,'.tif');
        sig1_file = strcat(sig1fileRoot,zkeep,signalchannel1,'.tif');
       
        membranestack(:,:,1) = imread(mem_file);
        signalstack1(:,:,1) = imread(sig1_file);
       
       if isfield(I,'signalchannel2') == 1
        sig2_file = strcat(sig2fileRoot,zkeep,signalchannel2,'.tif');
        signalstack2(:,:,1) = imread(sig2_file);
       end
        
       if isfield(I,'signalchannel3') == 1
        sig3_file = strcat(sig3fileRoot,zkeep,signalchannel3,'.tif');
        signalstack3(:,:,1) = imread(sig3_file);
       end
   
    case 2
        for frame = 1:frame_num;
            if frame < 10
            I.timestep = strcat('00',num2str(frame));
        else
            I.timestep = strcat('0',num2str(frame));
            end
        mem_file = strcat(membraneRoot,I.timestep,zkeep,memchannel,'.tif');
        sig1_file = strcat(sig1fileRoot, I.timestep, zkeep,signalchannel1,'.tif');
        
        membranestack(:,:,frame) = imread(mem_file);
        signalstack1(:,:,frame) = imread(sig1_file);
        
        if isfield(I,'signalchannel2') == 1
            sig2_file = strcat(sig2fileRoot, I.timestep, zkeep,signalchannel2,'.tif');
            signalstack2(:,:,frame) = imread(sig2_file);
        end
        end
end
        


O.membranestack = membranestack
O.signal1 = signalstack1

if isfield(I,'signalchannel2') == 1
    O.signal2 = signalstack2
end

if isfield(I,'signalchannel3') == 1
    O.signal3 = signalstack3
end

    
end


