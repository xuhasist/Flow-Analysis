function [meanFlowTableSize_1] = calculateFlowTableSize_mod2(allSwTableSize_list)
    
    meanFlowTableSize_1 = [];
    for i = 1:length(allSwTableSize_list)
        if isempty(allSwTableSize_list(i).flowNum)
            meanFlowTableSize_1 = [meanFlowTableSize_1, 0];
        else
            meanFlowTableSize_1 = [meanFlowTableSize_1, mean(allSwTableSize_list(i).flowNum)];
        end
    end
    
    meanFlowTableSize_1 = mean(meanFlowTableSize_1);
end