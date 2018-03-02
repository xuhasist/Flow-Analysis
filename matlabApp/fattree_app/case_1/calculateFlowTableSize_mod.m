function [meanFlowTableSize_1, meanFlowTableSize_2, meanFlowTableSize_3, meanFlowTableSize_4, meanFlowTableSize_5, swFlowEntryStruct_accumulation] = ...
    calculateFlowTableSize_mod(swFlowEntryStruct_accumulation)

    for i = 1:length(swFlowEntryStruct_accumulation)
        if isempty(swFlowEntryStruct_accumulation(i).entry)
            continue
        else
            % transfer strtime to datetime
            x = num2cell(datetime({swFlowEntryStruct_accumulation(i).entry.startTime}', 'Format', 'yyyy-MM-dd HH:mm:ss.SSS'));
            [swFlowEntryStruct_accumulation(i).entry.startTime] = deal(x{:});

            x = num2cell(datetime({swFlowEntryStruct_accumulation(i).entry.endTime}', 'Format', 'yyyy-MM-dd HH:mm:ss.SSS'));
            [swFlowEntryStruct_accumulation(i).entry.endTime] = deal(x{:});
        end
    end
    
    swTableSize_perMinute = [];
    
    begin_time = datetime('2009-12-18 00:26:04.398', 'Format', 'yyyy-MM-dd HH:mm:ss.SSS');
    end_time = datetime('2009-12-18 00:32:04.398', 'Format', 'yyyy-MM-dd HH:mm:ss.SSS');
    
    preEnd_tmp = ones(1, length(swFlowEntryStruct_accumulation));
    while begin_time ~= end_time
        begin_time
        
        preEnd = preEnd_tmp;
        allSwTableSize = [];
        
        for i = 1:length(swFlowEntryStruct_accumulation)
            if isempty(swFlowEntryStruct_accumulation(i).entry)
                allSwTableSize = [allSwTableSize, 0];
                continue
            else
                swEntryStartDatetime = swFlowEntryStruct_accumulation(i).entry(preEnd(i):end).startTime;
                swEntryEndDatetime = swFlowEntryStruct_accumulation(i).entry(preEnd(i):end).endTime;

                rows = (([swFlowEntryStruct_accumulation(i).entry(preEnd(i):end).startTime] >= begin_time) & ([swFlowEntryStruct_accumulation(i).entry(preEnd(i):end).startTime] < begin_time + minutes(1))) ...
                    | (([swFlowEntryStruct_accumulation(i).entry(preEnd(i):end).endTime] >= begin_time) & ([swFlowEntryStruct_accumulation(i).entry(preEnd(i):end).endTime] <= begin_time + minutes(1)));

                rows_index = find(rows) + preEnd(i) - 1;
                
                if isempty(rows_index)
                    allSwTableSize = [allSwTableSize, 0];
                    continue
                end

                s_time = [swFlowEntryStruct_accumulation(i).entry(rows_index).startTime];
                e_time = [swFlowEntryStruct_accumulation(i).entry(rows_index).endTime];
                flowEntryNumArray = [swFlowEntryStruct_accumulation(i).entry(rows_index).flowEntryNum];
                
                preEnd_tmp(i) = rows_index(end); % for next minute preEnd

                rows = s_time < begin_time;
                s_time(rows) = begin_time;

                rows = e_time > begin_time + minutes(1);
                e_time(rows) = begin_time + minutes(1);

                ration = minutes(e_time - s_time);
                ration = ration / sum(ration);

                tableSize = [];

                tableSize = flowEntryNumArray.* ration;
                tableSize_sum = sum(tableSize);
                
                allSwTableSize = [allSwTableSize, tableSize_sum];
            end
        end
        
        swTableSize_perMinute = [swTableSize_perMinute; allSwTableSize];
        begin_time = begin_time + minutes(1);
    end
    
    meanFlowTableSize_1 = mean(mean(swTableSize_perMinute, 2));
    
    rows = swTableSize_perMinute == 0;
    
    meanFlowTableSize_2 = [];
    for i = 1:size(swTableSize_perMinute, 1)
        meanFlowTableSize_2 = [meanFlowTableSize_2, mean(swTableSize_perMinute(i, ~rows(i,:)))];
    end
    
    rows = isnan(meanFlowTableSize_2);
    meanFlowTableSize_2(rows) = 0;
    meanFlowTableSize_2 = mean(meanFlowTableSize_2);
    
    first_n_sw_10percent = ceil(length(swFlowEntryStruct_accumulation) * 0.1);
    first_n_sw_25percent = ceil(length(swFlowEntryStruct_accumulation) * 0.25);
    first_n_sw_50percent = ceil(length(swFlowEntryStruct_accumulation) * 0.5);
    
    [sort_swTableSize_perMinute, ~] = sort(swTableSize_perMinute, 2, 'descend');
    
    meanFlowTableSize_3 = mean(mean(sort_swTableSize_perMinute(:,1:first_n_sw_10percent), 2));
    meanFlowTableSize_4 = mean(mean(sort_swTableSize_perMinute(:,1:first_n_sw_25percent), 2));
    meanFlowTableSize_5 = mean(mean(sort_swTableSize_perMinute(:,1:first_n_sw_50percent), 2));
end