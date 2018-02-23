function [meanFlowTableSize_1, meanFlowTableSize_2, meanFlowTableSize_3, meanFlowTableSize_4, meanFlowTableSize_5, meanFlowTableSize_6, meanFlowTableSize_7, meanFlowTableSize_8] = calculateFlowTableSize(swFlowEntryStruct)
    start_time = datetime('2009-12-18 00:26:04.398', 'Format', 'yyyy-MM-dd HH:mm:ss.SSS');
    end_time = datetime('2009-12-18 00:32:04.398', 'Format', 'yyyy-MM-dd HH:mm:ss.SSS');
    slot_num = minutes(end_time - start_time);
    
    flowTableSize = zeros(1, slot_num);
    finalSwNum = zeros(1, slot_num);
    
    swTableSize_perMinute = [];
    for sw = 1:length(swFlowEntryStruct)
        swTableSize = zeros(slot_num, 1)';
        
        if isempty(swFlowEntryStruct(sw).entry)
            continue
        else
            flowLoc = [];
            for i = 1:length(swFlowEntryStruct(sw).entry)
                entryTimeRange = {swFlowEntryStruct(sw).entry(i).startTime, swFlowEntryStruct(sw).entry(i).endTime};
                entryTimeRange = datetime(entryTimeRange,'Format','yyyy-MM-dd HH:mm:ss.SSS');
                
                sloc = floor(minutes(entryTimeRange(1) - start_time)) + 1;
                eloc = floor(minutes(entryTimeRange(2) - start_time)) + 1;
                
                flowLoc = [flowLoc, (sloc:eloc)];

                flowTableSize(sloc:eloc) = flowTableSize(sloc:eloc) + 1;
                swTableSize(sloc:eloc) = swTableSize(sloc:eloc) + 1;
            end
            
            finalSwNum(unique(flowLoc)) = finalSwNum(unique(flowLoc)) + 1;
        end
        
        swTableSize_perMinute = [swTableSize_perMinute, swTableSize'];
    end
    
    flowTableSize_1 = flowTableSize/length(swFlowEntryStruct);
    meanFlowTableSize_1 = mean(flowTableSize_1);
    
    flowTableSize_2 = flowTableSize./finalSwNum;
    meanFlowTableSize_2 = mean(flowTableSize_2);
    
    
    flowTableSize = zeros(1, slot_num);
    
    allSwFlowTableSize = cellfun(@(x) length(x), {swFlowEntryStruct.entry});
    [~, original_loc] = sort(allSwFlowTableSize, 'descend');
    
    first_n_sw_10percent = ceil(length(swFlowEntryStruct) * 0.1);
    for i = 1:first_n_sw_10percent
        sw = original_loc(i);
        
        if isempty(swFlowEntryStruct(sw).entry)
            continue
        else
            for j = 1:length(swFlowEntryStruct(sw).entry)
                entryTimeRange = {swFlowEntryStruct(sw).entry(j).startTime, swFlowEntryStruct(sw).entry(j).endTime};
                entryTimeRange = datetime(entryTimeRange,'Format','yyyy-MM-dd HH:mm:ss.SSS');
                
                sloc = floor(minutes(entryTimeRange(1) - start_time)) + 1;
                eloc = floor(minutes(entryTimeRange(2) - start_time)) + 1;

                flowTableSize(sloc:eloc) = flowTableSize(sloc:eloc) + 1;
            end
        end
    end
    
    flowTableSize_3 = flowTableSize./first_n_sw_10percent;
    meanFlowTableSize_3 = mean(flowTableSize_3);
    
    
    flowTableSize = zeros(1, slot_num);
    
    first_n_sw_25percent = ceil(length(swFlowEntryStruct) * 0.25);
    for i = 1:first_n_sw_25percent
        sw = original_loc(i);
        
        if isempty(swFlowEntryStruct(sw).entry)
            continue
        else
            for j = 1:length(swFlowEntryStruct(sw).entry)
                entryTimeRange = {swFlowEntryStruct(sw).entry(j).startTime, swFlowEntryStruct(sw).entry(j).endTime};
                entryTimeRange = datetime(entryTimeRange,'Format','yyyy-MM-dd HH:mm:ss.SSS');
                
                sloc = floor(minutes(entryTimeRange(1) - start_time)) + 1;
                eloc = floor(minutes(entryTimeRange(2) - start_time)) + 1;
                
                flowTableSize(sloc:eloc) = flowTableSize(sloc:eloc) + 1;
            end
        end
    end
    
    flowTableSize_4 = flowTableSize./first_n_sw_25percent;
    meanFlowTableSize_4 = mean(flowTableSize_4);
    
    
    flowTableSize = zeros(1, slot_num);
    
    first_n_sw_50percent = ceil(length(swFlowEntryStruct) * 0.5);
    for i = 1:first_n_sw_50percent
        sw = original_loc(i);
        
        if isempty(swFlowEntryStruct(sw).entry)
            continue
        else
            for j = 1:length(swFlowEntryStruct(sw).entry)
                entryTimeRange = {swFlowEntryStruct(sw).entry(j).startTime, swFlowEntryStruct(sw).entry(j).endTime};
                entryTimeRange = datetime(entryTimeRange,'Format','yyyy-MM-dd HH:mm:ss.SSS');
                
                sloc = floor(minutes(entryTimeRange(1) - start_time)) + 1;
                eloc = floor(minutes(entryTimeRange(2) - start_time)) + 1;

                flowTableSize(sloc:eloc) = flowTableSize(sloc:eloc) + 1;
            end
        end
    end
    
    flowTableSize_5 = flowTableSize./first_n_sw_50percent;
    meanFlowTableSize_5 = mean(flowTableSize_5);
    
    [sort_swTableSize_perMinute, ~] = sort(swTableSize_perMinute, 2, 'descend');
    
    meanFlowTableSize_6 = mean(mean(sort_swTableSize_perMinute(:,1:first_n_sw_10percent), 2));
    meanFlowTableSize_7 = mean(mean(sort_swTableSize_perMinute(:,1:first_n_sw_25percent), 2));
    meanFlowTableSize_8 = mean(mean(sort_swTableSize_perMinute(:,1:first_n_sw_50percent), 2));
end