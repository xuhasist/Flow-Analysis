function flowTraceTable = hierarchicalClustering_fixedPrefix(pl, g, swDistanceVector, hostIpTable, swInfTable, flowTraceTable)
    srcIp = flowTraceTable.SrcIp;
    srcIp = cellfun(@(x) strsplit(x, '.'), srcIp, 'UniformOutput', false);
    srcSubnet = cellfun(@(x) strcat(dec2bin(str2num(x{1}), 8), dec2bin(str2num(x{2}), 8)), srcIp, 'UniformOutput', false);
    
    dstIp = flowTraceTable.DstIp;
    dstIp = cellfun(@(x) strsplit(x, '.'), dstIp, 'UniformOutput', false);
    dstSubnet = cellfun(@(x) strcat(dec2bin(str2num(x{1}), 8), dec2bin(str2num(x{2}), 8)), dstIp, 'UniformOutput', false);
    
    subnetSet = cellfun(@(x) x(1:pl), srcSubnet, 'UniformOutput', false);
    subnetSet = [subnetSet, cellfun(@(x) x(1:pl), dstSubnet, 'UniformOutput', false)];
    [~, id] = unique(cell2mat(subnetSet), 'rows');
    subnetSet = subnetSet(id,:);
    
    group_index = 1;
    for i = 1:size(subnetSet, 1)
        rows = startsWith(srcSubnet, subnetSet{i, 1}) & startsWith(dstSubnet, subnetSet{i, 2});
        
        srcip_filter = flowTraceTable{rows, {'SrcIp'}};
        dstip_filter = flowTraceTable{rows, {'DstIp'}};
        
        srcHost = cellfun(@(x) hostIpTable{strcmp(hostIpTable.IP, x), {'Host'}}, srcip_filter);
        edge_sw_filter = cellfun(@(x) swInfTable{strcmp(swInfTable.SrcNode, x), {'DstNode'}}, srcHost);
        uniqueSrcEdgeSw = unique(edge_sw_filter);

        dstHost = cellfun(@(x) hostIpTable{strcmp(hostIpTable.IP, x), {'Host'}}, dstip_filter);
        edge_sw_filter = cellfun(@(x) swInfTable{strcmp(swInfTable.SrcNode, x), {'DstNode'}}, dstHost);
        uniqueDstEdgeSw = unique(edge_sw_filter);
        
        if length(uniqueSrcEdgeSw) == 1 && length(uniqueDstEdgeSw) == 1
            middleSrcSw = uniqueSrcEdgeSw;
            middleDstSw = uniqueDstEdgeSw;
        else
            if length(uniqueSrcEdgeSw) == 1
                middleSrcSw = uniqueSrcEdgeSw;
            else
                middleSrcSw = findMiddleSw(uniqueSrcEdgeSw, g, swDistanceVector);
            end

            if length(uniqueDstEdgeSw) == 1
                middleDstSw = uniqueDstEdgeSw;
            else
                middleDstSw = findMiddleSw(uniqueDstEdgeSw, g, swDistanceVector);
            end
        end
        
        flowTraceTable.MiddleSrcSw(rows) = {middleSrcSw};
        flowTraceTable.MiddleDstSw(rows) = {middleDstSw};
        flowTraceTable.HierarchicalGroup(rows) = group_index;
        
        group_index = group_index + 1;
    end
end

function middleSw = findMiddleSw(edgeSw, g, swDistanceVector)
    middleSw = -1;
    distance = 1;
    
    nodeNum = findnode(g, edgeSw);
    
    while middleSw == -1
        for k = 1:length(nodeNum)
            tmp_list{k} = find(ismember(swDistanceVector(nodeNum(k), :), (1:distance)));
        end
        
        merge_node = intersect(tmp_list{1}, tmp_list{2});
        for k = 3:length(tmp_list)
            merge_node = intersect(merge_node, tmp_list{k});
        end
        
        if ~isempty(merge_node)
            middleSw = g.Nodes.Name{merge_node(1)};
        end
        
        distance = distance + 1;
    end
end