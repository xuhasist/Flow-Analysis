function flowTraceTable = hierarchicalClustering_fixedPrefix(pl, g, swDistanceVector, hostIpTable, swInfTable, flowTraceTable, idx, group_num)
    group_index = 1;
    for i = 1:group_num
        group_flow = (idx == i);
        flow_index_filter = find(group_flow);
        
        group_flow = ismember(flowTraceTable.Index, flow_index_filter);
        flow_index_filter = find(group_flow);
        
        srcip_filter = flowTraceTable{group_flow, {'SrcIp'}};
        dstip_filter = flowTraceTable{group_flow, {'DstIp'}};
        
        srcSubnet = cellfun(@(x) strsplit(x, '.'), srcip_filter, 'UniformOutput', false);
        srcSubnet = cellfun(@(x) strcat(dec2bin(str2num(x{1}), 8), dec2bin(str2num(x{2}), 8)), srcSubnet, 'UniformOutput', false);
        
        dstSubnet = cellfun(@(x) strsplit(x, '.'), dstip_filter, 'UniformOutput', false);
        dstSubnet = cellfun(@(x) strcat(dec2bin(str2num(x{1}), 8), dec2bin(str2num(x{2}), 8)), dstSubnet, 'UniformOutput', false);

        subnetSet = cellfun(@(x) x(1:pl), srcSubnet, 'UniformOutput', false);
        subnetSet = [subnetSet, cellfun(@(x) x(1:pl), dstSubnet, 'UniformOutput', false)];
        [~, id] = unique(cell2mat(subnetSet), 'rows');
        subnetSet = subnetSet(id,:);
        
        for j = 1:size(subnetSet, 1)
            rows = startsWith(srcSubnet, subnetSet{j, 1}) & startsWith(dstSubnet, subnetSet{j, 2});
            flow_index = flow_index_filter(rows);
            
            srcip_filter = flowTraceTable{flow_index, {'SrcIp'}};
            dstip_filter = flowTraceTable{flow_index, {'DstIp'}};
            
            srcHost = cellfun(@(x) hostIpTable{strcmp(hostIpTable.IP, x), {'Host'}}, srcip_filter);
            srcEdgeSw_filter = cellfun(@(x) swInfTable{strcmp(swInfTable.SrcNode, x), {'DstNode'}}, srcHost);
            uniqueSrcEdgeSw = unique(srcEdgeSw_filter);

            dstHost = cellfun(@(x) hostIpTable{strcmp(hostIpTable.IP, x), {'Host'}}, dstip_filter);
            dstEdgeSw_filter = cellfun(@(x) swInfTable{strcmp(swInfTable.SrcNode, x), {'DstNode'}}, dstHost);
            uniqueDstEdgeSw = unique(dstEdgeSw_filter);
            
            if length(uniqueSrcEdgeSw) == 1 && length(uniqueDstEdgeSw) == 1
                middleSrcSw = uniqueSrcEdgeSw;
                middleDstSw = uniqueDstEdgeSw;
            else
                if length(uniqueSrcEdgeSw) == 1
                    middleSrcSw = uniqueSrcEdgeSw;
                else
                    middleSrcSw = findMiddleSw(uniqueSrcEdgeSw, g, swDistanceVector);
                    middleSrcSw = {middleSrcSw};
                end

                if length(uniqueDstEdgeSw) == 1
                    middleDstSw = uniqueDstEdgeSw;
                else
                    middleDstSw = findMiddleSw(uniqueDstEdgeSw, g, swDistanceVector);
                    middleDstSw = {middleDstSw};
                end
            end
            
            flowTraceTable.MiddleSrcSw(flow_index) = middleSrcSw;
            flowTraceTable.MiddleDstSw(flow_index) = middleDstSw;
            flowTraceTable.HierarchicalGroup(flow_index) = group_index;

            group_index = group_index + 1;
        end
    end
    
    % assign different port to clusters which have the same prefix
    hieGroupId = unique(flowTraceTable.HierarchicalGroup);
    subnetSet = [];
    
    for i = 1:length(hieGroupId)
        if hieGroupId(i) == 0
            continue
        end

        rows = (flowTraceTable.HierarchicalGroup == hieGroupId(i));

        srcip_filter = flowTraceTable{find(rows, 1), {'SrcIp'}};
        dstip_filter = flowTraceTable{find(rows, 1), {'DstIp'}};

        srcSubnet = strsplit(srcip_filter{1}, '.');
        srcSubnet = strcat(dec2bin(str2num(srcSubnet{1}), 8), dec2bin(str2num(srcSubnet{2}), 8));

        dstSubnet = strsplit(dstip_filter{1}, '.');
        dstSubnet = strcat(dec2bin(str2num(dstSubnet{1}), 8), dec2bin(str2num(dstSubnet{2}), 8));

        subnetSet = [subnetSet; {srcSubnet(1:pl)}, {dstSubnet(1:pl)}];
    end

    [~, id] = unique(cell2mat(subnetSet), 'rows');
    uniqueSubnetSet = subnetSet(id,:);

    for i = 1:size(uniqueSubnetSet, 1)
        rows = startsWith(subnetSet(:, 1), uniqueSubnetSet{i, 1}) & startsWith(subnetSet(:, 2), uniqueSubnetSet{i, 2});
        groupId = hieGroupId(rows);

        randPort = randperm(64512, length(groupId)) + 1023;

        for j = 1:length(groupId)
            rows = (flowTraceTable.HierarchicalGroup == groupId(j));
            flowTraceTable.ClusterPort(rows) = randPort(j);
        end
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