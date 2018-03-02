function [swFlowEntryStruct_accumulation, swPreLower] = ...
    updateSwStruct(finalPath, swFlowEntryStruct, swFlowEntryStruct_accumulation, ...
    flowStartDatetime, flowEndDatetime,flowEndStrtime, swPreLower, flowEntry)

    for i = 2:length(finalPath)-1
        sw = finalPath(i);
        k = length(swFlowEntryStruct_accumulation(sw).entry);
        
        lower = -1;
        upper = -1;
        
        if ~isempty(swFlowEntryStruct_accumulation(sw).entry)  
            rows = (flowStartDatetime >= datetime({swFlowEntryStruct_accumulation(sw).entry(swPreLower(sw):end).startTime}', 'Format', 'yyyy-MM-dd HH:mm:ss.SSS')) ...
                & (flowStartDatetime < datetime({swFlowEntryStruct_accumulation(sw).entry(swPreLower(sw):end).endTime}', 'Format', 'yyyy-MM-dd HH:mm:ss.SSS'));
            
            if find(rows == 1)
                lower = (find(rows) + swPreLower(sw) - 1);
            end
            
            rows = (flowEndDatetime >= datetime({swFlowEntryStruct_accumulation(sw).entry(swPreLower(sw):end).startTime}', 'Format', 'yyyy-MM-dd HH:mm:ss.SSS')) ...
                & (flowEndDatetime < datetime({swFlowEntryStruct_accumulation(sw).entry(swPreLower(sw):end).endTime}', 'Format', 'yyyy-MM-dd HH:mm:ss.SSS'));
            
            if find(rows == 1)
                upper = (find(rows) + swPreLower(sw) - 1);
            end
        end
        
        if lower == -1 && upper == -1
            swFlowEntryStruct_accumulation(sw).entry(k+1).startTime = flowEntry.startTime;
            swFlowEntryStruct_accumulation(sw).entry(k+1).endTime = flowEndStrtime;
            swFlowEntryStruct_accumulation(sw).entry(k+1).flowEntryNum = 1;
        elseif lower == upper && upper ~= -1
            swFlowEntryStruct_accumulation(sw).entry(k+1).startTime = flowEntry.startTime;
            swFlowEntryStruct_accumulation(sw).entry(k+1).endTime = flowEndStrtime;
            swFlowEntryStruct_accumulation(sw).entry(k+1).flowEntryNum = 1 + swFlowEntryStruct_accumulation(sw).entry(lower).flowEntryNum;

            swFlowEntryStruct_accumulation(sw).entry(k+2).startTime = flowEndStrtime;
            swFlowEntryStruct_accumulation(sw).entry(k+2).endTime = swFlowEntryStruct_accumulation(sw).entry(lower).endTime;
            swFlowEntryStruct_accumulation(sw).entry(k+2).flowEntryNum = swFlowEntryStruct_accumulation(sw).entry(lower).flowEntryNum;

            if strcmp(swFlowEntryStruct_accumulation(sw).entry(lower).startTime, flowEntry.startTime)
                swFlowEntryStruct_accumulation(sw).entry(lower) = [];
            else
                swFlowEntryStruct_accumulation(sw).entry(lower).endTime = flowEntry.startTime;
            end
        elseif lower == k && upper == -1
            swFlowEntryStruct_accumulation(sw).entry(k+1).startTime = swFlowEntryStruct_accumulation(sw).entry(lower).endTime;
            swFlowEntryStruct_accumulation(sw).entry(k+1).endTime = flowEndStrtime;
            swFlowEntryStruct_accumulation(sw).entry(k+1).flowEntryNum = 1;

            swFlowEntryStruct_accumulation(sw).entry(k+2).startTime = flowEntry.startTime;
            swFlowEntryStruct_accumulation(sw).entry(k+2).endTime = swFlowEntryStruct_accumulation(sw).entry(lower).endTime;
            swFlowEntryStruct_accumulation(sw).entry(k+2).flowEntryNum = 1 + swFlowEntryStruct_accumulation(sw).entry(lower).flowEntryNum;

            if strcmp(swFlowEntryStruct_accumulation(sw).entry(lower).startTime, flowEntry.startTime)
                swFlowEntryStruct_accumulation(sw).entry(lower) = [];
            else
                swFlowEntryStruct_accumulation(sw).entry(lower).endTime = flowEntry.startTime;
            end
        elseif lower < upper || upper == -1
            if upper == -1
                for n = lower+1:k
                    swFlowEntryStruct_accumulation(sw).entry(n).flowEntryNum = 1 + swFlowEntryStruct_accumulation(sw).entry(n).flowEntryNum;
                end

                swFlowEntryStruct_accumulation(sw).entry(k+1).startTime = swFlowEntryStruct_accumulation(sw).entry(k).endTime;
                swFlowEntryStruct_accumulation(sw).entry(k+1).endTime = flowEndStrtime;
                swFlowEntryStruct_accumulation(sw).entry(k+1).flowEntryNum = 1;
            else
                for n = lower+1:upper-1
                    swFlowEntryStruct_accumulation(sw).entry(n).flowEntryNum = 1 + swFlowEntryStruct_accumulation(sw).entry(n).flowEntryNum;
                end

                swFlowEntryStruct_accumulation(sw).entry(k+1).startTime = flowEndStrtime;
                swFlowEntryStruct_accumulation(sw).entry(k+1).endTime = swFlowEntryStruct_accumulation(sw).entry(upper).endTime;
                swFlowEntryStruct_accumulation(sw).entry(k+1).flowEntryNum = swFlowEntryStruct_accumulation(sw).entry(upper).flowEntryNum;

                swFlowEntryStruct_accumulation(sw).entry(upper).endTime = flowEndStrtime;
                swFlowEntryStruct_accumulation(sw).entry(upper).flowEntryNum = 1 + swFlowEntryStruct_accumulation(sw).entry(upper).flowEntryNum;
            end

            swFlowEntryStruct_accumulation(sw).entry(k+2).startTime = flowEntry.startTime;
            swFlowEntryStruct_accumulation(sw).entry(k+2).endTime = swFlowEntryStruct_accumulation(sw).entry(lower).endTime;
            swFlowEntryStruct_accumulation(sw).entry(k+2).flowEntryNum = 1 +  swFlowEntryStruct_accumulation(sw).entry(lower).flowEntryNum;

            if strcmp(swFlowEntryStruct_accumulation(sw).entry(lower).startTime, flowEntry.startTime)
                swFlowEntryStruct_accumulation(sw).entry(lower) = [];
            else
                swFlowEntryStruct_accumulation(sw).entry(lower).endTime = flowEntry.startTime;
            end
        end
        
        [~, ind] = sortrows({swFlowEntryStruct_accumulation(sw).entry.startTime}');
        swFlowEntryStruct_accumulation(sw).entry = swFlowEntryStruct_accumulation(sw).entry(ind);

        if lower == -1
            swPreLower(sw) = length(swFlowEntryStruct_accumulation(sw).entry);
        else
            swPreLower(sw) = lower;
        end
    end 
end