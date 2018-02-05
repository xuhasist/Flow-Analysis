function [linkThputStruct, linkPreLower] = updateLinkStruct(finalPath, g, linkThputStruct, flowStartDatetime, flowEndDatetime, flowEndStrtime, linkPreLower, flowEntry, flowRate)
    for j = 1:length(finalPath)-1
        edge = findedge(g, finalPath(j), finalPath(j+1));

        k = length(linkThputStruct(edge).entry);

        lower = -1;
        upper = -1;

        if ~isempty(linkThputStruct(edge).entry)           
            rows = (flowStartDatetime >= datetime({linkThputStruct(edge).entry(linkPreLower(edge):end).startTime}', 'Format', 'yyyy-MM-dd HH:mm:ss.SSS')) ...
                & (flowStartDatetime < datetime({linkThputStruct(edge).entry(linkPreLower(edge):end).endTime}', 'Format', 'yyyy-MM-dd HH:mm:ss.SSS'));
            
            if find(rows == 1)
                lower = (find(rows) + linkPreLower(edge) - 1);
            end

            rows = (flowEndDatetime >= datetime({linkThputStruct(edge).entry(linkPreLower(edge):end).startTime}', 'Format', 'yyyy-MM-dd HH:mm:ss.SSS')) ...
                & (flowEndDatetime < datetime({linkThputStruct(edge).entry(linkPreLower(edge):end).endTime}', 'Format', 'yyyy-MM-dd HH:mm:ss.SSS'));
            
            if find(rows == 1)
                upper = (find(rows) + linkPreLower(edge) - 1);
            end
        end

        if lower == -1 && upper == -1
            linkThputStruct(edge).entry(k+1).startTime = flowEntry.startTime;
            linkThputStruct(edge).entry(k+1).endTime = flowEndStrtime;
            linkThputStruct(edge).entry(k+1).load = flowRate;
            linkThputStruct(edge).entry(k+1).flowNum = 1;
        elseif lower == upper && upper ~= -1
            linkThputStruct(edge).entry(k+1).startTime = flowEntry.startTime;
            linkThputStruct(edge).entry(k+1).endTime = flowEndStrtime;
            linkThputStruct(edge).entry(k+1).load = flowRate +  linkThputStruct(edge).entry(lower).load;
            linkThputStruct(edge).entry(k+1).flowNum = 1 + linkThputStruct(edge).entry(lower).flowNum;

            linkThputStruct(edge).entry(k+2).startTime = flowEndStrtime;
            linkThputStruct(edge).entry(k+2).endTime = linkThputStruct(edge).entry(lower).endTime;
            linkThputStruct(edge).entry(k+2).load = linkThputStruct(edge).entry(lower).load;
            linkThputStruct(edge).entry(k+2).flowNum = linkThputStruct(edge).entry(lower).flowNum;

            if strcmp(linkThputStruct(edge).entry(lower).startTime, flowEntry.startTime)
                linkThputStruct(edge).entry(lower) = [];
            else
                linkThputStruct(edge).entry(lower).endTime = flowEntry.startTime;
            end
        elseif lower == k && upper == -1
            linkThputStruct(edge).entry(k+1).startTime = linkThputStruct(edge).entry(lower).endTime;
            linkThputStruct(edge).entry(k+1).endTime = flowEndStrtime;
            linkThputStruct(edge).entry(k+1).load = flowRate;
            linkThputStruct(edge).entry(k+1).flowNum = 1;

            linkThputStruct(edge).entry(k+2).startTime = flowEntry.startTime;
            linkThputStruct(edge).entry(k+2).endTime = linkThputStruct(edge).entry(lower).endTime;
            linkThputStruct(edge).entry(k+2).load = flowRate +  linkThputStruct(edge).entry(lower).load;
            linkThputStruct(edge).entry(k+2).flowNum = 1 + linkThputStruct(edge).entry(lower).flowNum;

            if strcmp(linkThputStruct(edge).entry(lower).startTime, flowEntry.startTime)
                linkThputStruct(edge).entry(lower) = [];
            else
                linkThputStruct(edge).entry(lower).endTime = flowEntry.startTime;
            end
        elseif lower < upper || upper == -1
            if upper == -1
                for n = lower+1:k
                    linkThputStruct(edge).entry(n).load = flowRate + linkThputStruct(edge).entry(n).load;
                    linkThputStruct(edge).entry(n).flowNum = 1 + linkThputStruct(edge).entry(n).flowNum;
                end

                linkThputStruct(edge).entry(k+1).startTime = linkThputStruct(edge).entry(k).endTime;
                linkThputStruct(edge).entry(k+1).endTime = flowEndStrtime;
                linkThputStruct(edge).entry(k+1).load = flowRate;
                linkThputStruct(edge).entry(k+1).flowNum = 1;
            else
                for n = lower+1:upper-1
                    linkThputStruct(edge).entry(n).load = flowRate + linkThputStruct(edge).entry(n).load;
                    linkThputStruct(edge).entry(n).flowNum = 1 + linkThputStruct(edge).entry(n).flowNum;
                end

                linkThputStruct(edge).entry(k+1).startTime = flowEndStrtime;
                linkThputStruct(edge).entry(k+1).endTime = linkThputStruct(edge).entry(upper).endTime;
                linkThputStruct(edge).entry(k+1).load = linkThputStruct(edge).entry(upper).load;
                linkThputStruct(edge).entry(k+1).flowNum = linkThputStruct(edge).entry(upper).flowNum;

                linkThputStruct(edge).entry(upper).endTime = flowEndStrtime;
                linkThputStruct(edge).entry(upper).load = flowRate + linkThputStruct(edge).entry(upper).load;
                linkThputStruct(edge).entry(upper).flowNum = 1 + linkThputStruct(edge).entry(upper).flowNum;
            end

            linkThputStruct(edge).entry(k+2).startTime = flowEntry.startTime;
            linkThputStruct(edge).entry(k+2).endTime = linkThputStruct(edge).entry(lower).endTime;
            linkThputStruct(edge).entry(k+2).load = flowRate +  linkThputStruct(edge).entry(lower).load;
            linkThputStruct(edge).entry(k+2).flowNum = 1 +  linkThputStruct(edge).entry(lower).flowNum;

            if strcmp(linkThputStruct(edge).entry(lower).startTime, flowEntry.startTime)
                linkThputStruct(edge).entry(lower) = [];
            else
                linkThputStruct(edge).entry(lower).endTime = flowEntry.startTime;
            end
        end

        [tmp, ind] = sortrows({linkThputStruct(edge).entry.startTime}');
        linkThputStruct(edge).entry = linkThputStruct(edge).entry(ind);

        if lower == -1
            linkPreLower(edge) = length(linkThputStruct(edge).entry);
        else
            linkPreLower(edge) = lower;
        end
    end
end