function [params] = multilayer_reorg_4suit(filename,units) 
%%% ADD THESE VARIABLES %%%
    %filename = 'n:\DATA\Betanitas\!Mouse Gramophon\2_Imaging\photostim\877\2022_10_14_mouse877_behaviour_test_selected.mesc';    
    %templatefile = 'n:\DATA\Betanitas\!Mouse Gramophon\2_Imaging\photostim\877\2022_10_14_mouse877_layer_demixing_template.mesc';
    %units = 1:189;
%%% ------------------- %%%
    addpath('D:\analysis codes\Analysis\VR_Abhrajyoti\Raw_data_importers\NoRMCorre-master');
    % find number of layers
    fieldname = strcat('/MSession_0/MUnit_',num2str(units(1)),'/');
    attname = 'Slices';
    layers = h5readatt(filename,fieldname,attname);   % number of layers in the volume
    params.layers = double(layers);
    % find min volume   
    reps = length(units);
    minframe = 10000;
    for rep = units 
        fieldname = strcat('/MSession_0/MUnit_',num2str(rep),'/');
        attname = 'ZDim';
        datatemp = h5readatt(filename,fieldname,attname);
        if datatemp < minframe
            minframe = datatemp;
        end
    end
    minframe = double(minframe);
    minvolume = floor(minframe/layers); %shortest measurement lenght, will truncate all measurement to this lenght
    params.minframe = minframe;
    params.minvolume = minvolume;
    fieldname = strcat('/MSession_0/MUnit_',num2str(units(1)),'/');
    attname = 'TStepInMs';
    params.tstep = double(h5readatt(filename,fieldname,attname));    
    clear layerdata
    % code chanege that it goes throught the whole datafile for evey layer
    % it will be more data reading, but as it don't have all layer in the
    % memory at once might still runs faster
    for iLayer = 1:layers
        for rep = units 
            fieldname = strcat('/MSession_0/MUnit_',num2str(rep),'/Channel_0');
            datatemp = h5read(filename,fieldname);
            if rep == units(1) 
                layerdata = uint16(datatemp(:,:,iLayer:layers:minframe));
            else 
                layerdata = cat(3,layerdata,datatemp(:,:,iLayer:layers:minframe));
            end
            mMsg = strcat('processing: unit',{' '},num2str(rep),', layer',{' '},num2str(iLayer));
            fprintf(char(mMsg));
            fprintf('\n')
        end
        %apply MESc conversion on layerdata
        fieldname = strcat('/MSession_0/MUnit_',num2str(units(1)),'/');
        attname = 'Channel_0_Conversion_ConversionLinearOffset';
        linOffset = h5readatt(filename,fieldname,attname);   % number of layers in the volume
        layerdata = layerdata + linOffset;
        %run rigid motion correction
        %layerdata = normcorre_batch(layerdata);
        layerdata = layerdata;
        %define outputfilename
        [fPath, fName, ~] = fileparts(filename);
        fPathNew = char(strcat(fPath,{'\layerData'}));
        if ~exist(fPathNew, 'dir'), mkdir(fPathNew); end 
      %next line only needed if tempalates X-Y size is not correct
        %datatemp = imresize(layerdata(lay).data,[512,512]);
        outfilename = char(strcat(fPathNew,{'\'},fName,{'_layer'},num2str(iLayer),'CorrSimp.h5'));
%         if isfile(outfilename), delete(outfilename); end
      %next line only needed for mesc type export
        %status = copyfile(templatefile, outfilename);
        outfieldname = strcat('/Data');
        [xSize,ySize,zSize] = size(layerdata);
        h5create(outfilename,outfieldname,[xSize ySize Inf],'Datatype','uint16',...
           'Chunksize',[xSize ySize 1],'Deflate',1);
        %fill up attributes in the new unit
        fprintf('Writing layer data to file... hang in there');
        fprintf('\n')
        for iFrame = 1:zSize
            h5write(outfilename,outfieldname,layerdata(:,:,iFrame),[1 1 iFrame],[xSize ySize 1]);      
        end   
        %save export parameters
        paramfilename = char(strcat(fPathNew,{'\'},fName,{'_exportParams.mat'}));
        save(paramfilename,'params');
    end
    
end %end of the main function

  

