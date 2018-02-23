function flowTraceTable = similarityClustering_tableThreshold(g, hostIpTable, swInfTable, flowTraceTable, idx, group_num)
    group_index = 1;
    for i = 1:group_num
        group_flow = (idx == i);
        flow_index_filter = find(group_flow);
        
        group_flow = ismember(flowTraceTable.Index, flow_index_filter);
        flow_index_filter = find(group_flow);
        
        srcip_filter = flowTraceTable{group_flow, {'SrcIp'}};
        dstip_filter = flowTraceTable{group_flow, {'DstIp'}};
        
        srcHost = cellfun(@(x) hostIpTable{strcmp(hostIpTable.IP, x), {'Host'}}, srcip_filter);
        edge_sw_filter = cellfun(@(x) swInfTable{strcmp(swInfTable.SrcNode, x), {'DstNode'}}, srcHost);
        uniqueSrcEdgeSw = findnode(g, edge_sw_filter);

        dstHost = cellfun(@(x) hostIpTable{strcmp(hostIpTable.IP, x), {'Host'}}, dstip_filter);
        edge_sw_filter = cellfun(@(x) swInfTable{strcmp(swInfTable.SrcNode, x), {'DstNode'}}, dstHost);
        uniqueDstEdgeSw = findnode(g, edge_sw_filter);
        
        swPair = [uniqueSrcEdgeSw, uniqueDstEdgeSw];
        [~, id] = unique(swPair, 'rows');
        uniqueSwPair = swPair(id, :);
        
        for j = 1:size(uniqueSwPair, 1)
            rows = ismember(swPair(:,:), uniqueSwPair(j,:), 'rows');
            flow_index = flow_index_filter(rows);

            if length(flow_index) == 1
                flowTraceTable.Group(flow_index) = group_index;
                flowTraceTable.Prefix(flow_index) = 32;
                
                group_index = group_index + 1;
            else
                flowTraceTable.Group(flow_index) = group_index;
                group_index = group_index + 1;
                
                % calculate longest prefix length
                srcIp = flowTraceTable.SrcIp(flow_index);
                srcIp = cellfun(@(x) strsplit(x, '.'), srcIp, 'UniformOutput', false);
                srcSubnet = cellfun(@(x) strcat(dec2bin(str2num(x{1}), 8), dec2bin(str2num(x{2}), 8), dec2bin(str2num(x{3}), 8), dec2bin(str2num(x{4}), 8)), srcIp, 'UniformOutput', false);

                pl_temp = 32;
                for k = 2:length(srcSubnet)
                    resultSrcSubnet = ~xor(logical(srcSubnet{k-1}(1:pl_temp)-'0'), logical(srcSubnet{k}(1:pl_temp)-'0'));
                    srcFirstZero = find(resultSrcSubnet == 0, 1);
                    
                    if srcFirstZero == 17
                        break;
                    elseif isempty(srcFirstZero)
                        srcFirstZero = length(resultSrcSubnet) + 1;
                        continue;
                    else
                        pl_temp = srcFirstZero - 1;
                    end
                end
                
                if srcFirstZero == 17
                    continue;
                end
                
                dstIp = flowTraceTable.DstIp(flow_index);
                dstIp = cellfun(@(x) strsplit(x, '.'), dstIp, 'UniformOutput', false);
                dstSubnet = cellfun(@(x) strcat(dec2bin(str2num(x{1}), 8), dec2bin(str2num(x{2}), 8), dec2bin(str2num(x{3}), 8), dec2bin(str2num(x{4}), 8)), dstIp, 'UniformOutput', false);

                pl_temp = 32;
                for k = 2:length(dstSubnet)
                    resultDstSubnet = ~xor(logical(dstSubnet{k-1}(1:pl_temp)-'0'), logical(dstSubnet{k}(1:pl_temp)-'0'));
                    dstFirstZero = find(resultDstSubnet == 0, 1);
                    
                    if dstFirstZero == 17
                        break;
                    elseif isempty(dstFirstZero)
                        dstFirstZero = length(resultDstSubnet) + 1;
                        continue;
                    else
                        pl_temp = dstFirstZero - 1;
                    end
                end
                
                if dstFirstZero == 17
                    continue;
                else
                    flowTraceTable.prefix(flow_index) = min(srcFirstZero, dstFirstZero) - 1;
                end
            end
        end
    end
end