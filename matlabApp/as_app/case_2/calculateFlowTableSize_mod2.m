function [meanFlowTableSize_1, meanFlowTableSize_2, meanFlowTableSize_3, meanFlowTableSize_4] = calculateFlowTableSize_mod2(allSwTableSize_list)
    
    meanFlowTableSize = [];
    for i = 1:length(allSwTableSize_list)
        if isempty(allSwTableSize_list(i).flowNum)
            meanFlowTableSize = [meanFlowTableSize, 0];
        else
            meanFlowTableSize = [meanFlowTableSize, mean(allSwTableSize_list(i).flowNum)];
        end
    end
    
    meanFlowTableSize = sort(meanFlowTableSize, 'descend');
    
    meanFlowTableSize_1 = mean(meanFlowTableSize);
    
    first_n_sw_10percent = ceil(length(allSwTableSize_list) * 0.1);
    first_n_sw_25percent = ceil(length(allSwTableSize_list) * 0.25);
    first_n_sw_50percent = ceil(length(allSwTableSize_list) * 0.5);
    
    meanFlowTableSize_2 = mean(meanFlowTableSize(1:first_n_sw_10percent));
    meanFlowTableSize_3 = mean(meanFlowTableSize(1:first_n_sw_25percent));
    meanFlowTableSize_4 = mean(meanFlowTableSize(1:first_n_sw_50percent));
end