function meanFlowTableSize = calculateFlowTableSize(swFlowEntryStruct)
    start_time = datetime('2009-12-18 00:26', 'InputFormat', 'yyyy-MM-dd HH:mm');
    end_time = datetime('2009-12-18 01:33', 'InputFormat', 'yyyy-MM-dd HH:mm');
    slot_num = minutes(end_time - start_time);
    
    flowTableSize = zeros(1, slot_num);
    allSwMeanFlowTableSize = [];
    
    for sw = 1:length(swFlowEntryStruct)
        if isempty(swFlowEntryStruct(sw).entry)
            allSwMeanFlowTableSize = [allSwMeanFlowTableSize, 0];
            continue
        else
            for i = 1:length(swFlowEntryStruct(sw).entry)
                entryTimeRange = {swFlowEntryStruct(sw).entry(i).startTime, swFlowEntryStruct(sw).entry(i).endTime};
                entryTimeRange = datetime(entryTimeRange,'Format','yyyy-MM-dd HH:mm:ss.SSS');
                
                sloc = floor(minutes(entryTimeRange(1) - start_time)) + 1;
                eloc = floor(minutes(entryTimeRange(2) - start_time)) + 1;

                flowTableSize(sloc:eloc) = flowTableSize(sloc:eloc) + 1;
            end
        end
        allSwMeanFlowTableSize = [allSwMeanFlowTableSize, mean(flowTableSize)];
    end
    
    meanFlowTableSize = mean(allSwMeanFlowTableSize);
end