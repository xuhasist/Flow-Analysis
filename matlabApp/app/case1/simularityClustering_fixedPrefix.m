function flowTraceTable = simularityClustering_fixedPrefix(pl, flowTraceTable, flowSequence)
    if pl < 16
        original_pl = pl;
        pl = 16;
    end
    
    [idx, group_num] = doKmeans(flowSequence);
    
    group_index = 1;
    for i = 1:group_num
        group_flow = (idx == i);
        flow_index_filter = find(group_flow);
        
        group_flow = ismember(flowTraceTable.Index, flow_index_filter);
        flow_index_filter = find(group_flow);
        
        srcip_filter = flowTraceTable{group_flow, {'SrcIp'}};
        dstip_filter = flowTraceTable{group_flow, {'DstIp'}};
        
        srcSubnet = cellfun(@(x) strsplit(x, '.'), srcip_filter, 'UniformOutput', false);
        srcSubnet = cellfun(@(x) strcat(dec2bin(str2num(x{1}), 8), dec2bin(str2num(x{2}), 8), dec2bin(str2num(x{3}), 8), dec2bin(str2num(x{4}), 8)), srcSubnet, 'UniformOutput', false);
        
        dstSubnet = cellfun(@(x) strsplit(x, '.'), dstip_filter, 'UniformOutput', false);
        dstSubnet = cellfun(@(x) strcat(dec2bin(str2num(x{1}), 8), dec2bin(str2num(x{2}), 8), dec2bin(str2num(x{3}), 8), dec2bin(str2num(x{4}), 8)), dstSubnet, 'UniformOutput', false);

        subnetSet = cellfun(@(x) x(1:pl), srcSubnet, 'UniformOutput', false);
        subnetSet = [subnetSet, cellfun(@(x) x(1:pl), dstSubnet, 'UniformOutput', false)];
        [~, id] = unique(cell2mat(subnetSet), 'rows');
        subnetSet = subnetSet(id,:);

        for j = 1:size(subnetSet, 1)
            rows = startsWith(srcSubnet, subnetSet{j, 1}) & startsWith(dstSubnet, subnetSet{j, 2});
            flow_index = flow_index_filter(rows);
            
            flowTraceTable.Group(flow_index) = group_index;
            group_index = group_index + 1;
        end
    end
end

function [idx, k] = doKmeans(flowSequence)
    k = 0;
    pre_avgDistance = -1;
    avgDistance = -1;
    
    while pre_avgDistance == -1 || ~(avgDistance >= pre_avgDistance * (95/100) && avgDistance <= pre_avgDistance)
        k = k + 1;
        pre_avgDistance = avgDistance;
        
        [idx, C, sumd] = kmeans(flowSequence, k);
        
        avg_sumd = [];
        for i = 1:length(sumd)
            avg_sumd(i) = (sumd(i) / length(find(idx == i)));
        end
        avgDistance = mean(avg_sumd);
    end
end