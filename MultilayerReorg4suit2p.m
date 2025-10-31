function [params] = MultilayerReorg4suit2p

%%% MultilayerReorg4suit2p
%This function extracts the individual layers of imaging data from a
%volumetric data, producing as many files with *.h5 extenstion as there are
%layers. For example, if the volumetric imaging was performed with 3
%layers, this function will produce 3 files with extensions *.h5. The
%fluorescence data will be found under the fieldname 'Data' in each *.h5
%file.
%Inputs by user:
%Define units to analyze (example) - 10:51 OR [10:24,26:51]

try
    [nameOfFile,filePath] = uigetfile('*.mesc','Select the MESc file to proceed...');
    fullPath = strcat(filePath,nameOfFile);

    measurementUnitRange = input(sprintf('Define units to analyze\n'));

    % find number of layers
    fieldname = strcat('/MSession_0/MUnit_',num2str(measurementUnitRange(1)),'/');
    attname = 'Slices';
    layers = h5readatt(fullPath,fieldname,attname);   % number of layers in the volume
    params.layers = double(layers);

    % find min volume
    reps = length(measurementUnitRange);
    minframe = 10000;
    for rep = measurementUnitRange
        fieldname = strcat('/MSession_0/MUnit_',num2str(rep),'/');
        attname = 'ZDim';
        datatemp = h5readatt(fullPath,fieldname,attname);
        if datatemp < minframe
            minframe = datatemp;
        end
    end
    minframe = double(minframe);
    minvolume = floor(minframe/layers); %shortest measurement lenght, will truncate all measurement to this lenght
    params.minframe = minframe;
    params.minvolume = minvolume;
    fieldname = strcat('/MSession_0/MUnit_',num2str(measurementUnitRange(1)),'/');
    attname = 'TStepInMs';
    params.tstep = double(h5readatt(fullPath,fieldname,attname));
    clear layerdata


    for iLayer = 1:layers
        for rep = measurementUnitRange
            fieldname = strcat('/MSession_0/MUnit_',num2str(rep),'/Channel_0');
            datatemp = h5read(fullPath,fieldname);
            if rep == measurementUnitRange(1)
                layerdata = uint16(datatemp(:,:,iLayer:layers:minframe));
            else
                layerdata = cat(3,layerdata,datatemp(:,:,iLayer:layers:minframe));
            end
            mMsg = strcat('processing: unit',{' '},num2str(rep),', layer',{' '},num2str(iLayer));
            fprintf(char(mMsg));
            fprintf('\n')
        end

        %apply MESc PMT dark noise on layerdata
        fieldname = strcat('/MSession_0/MUnit_',num2str(measurementUnitRange(1)),'/');
        attname = 'Channel_0_Conversion_ConversionLinearOffset';
        linOffset = h5readatt(fullPath,fieldname,attname);   % number of layers in the volume
        layerdata = layerdata + linOffset;

        %define outputfilename
        [fPath, fName, ~] = fileparts(fullPath);
        fPathNew = char(strcat(fPath,{'\layerData'}));
        if ~exist(fPathNew, 'dir'), mkdir(fPathNew); end

        outfilename = char(strcat(fPathNew,{'\'},fName,{'_layer'},num2str(iLayer),'CorrSimp.h5'));
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

        fprintf('Layer demixing complete!');
        fprintf('\n')
    end

catch
end