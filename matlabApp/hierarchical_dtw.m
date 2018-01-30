function [flow_table, hie_count] = hierarchical_dtw(g, sw_vector, host_ip, link_if, sw_tooManyFlowEntry, flowEntry_threshold, flow_final_path, hie_count, flow_table, i)
    'do hierarchical clustering'
    
    hie_count = hie_count + 1;
    
    for i = 1:length(sw_tooManyFlowEntry)
        pass_flow = cellfun(@(x) any(ismember(x, sw_tooManyFlowEntry(i))), flow_final_path, 'UniformOutput', false);
        pass_flow = cell2mat(pass_flow)';
        
        groupId = flow_table{pass_flow, {'group'}};
        groupId = unique(groupId);
        
        group_num = length(groupId);
        has_group = [];
        
        while group_num >= flowEntry_threshold
            group_size = repmat(-1, length(groupId), 1);
            hie_group_list = repmat(-1, length(groupId), 1);
            
            if length(groupId) <= 1
                break;
            end
            
            for j = 1:length(groupId)
                rows = (flow_table.group == groupId(j));
                flow_hie_group = unique(flow_table.hie_group(rows));
                hie_group_list(j) = flow_hie_group;
                
                if flow_hie_group == -1
                    group_size(j) = sum(flow_table{rows, {'bytes'}});
                else
                    flow_rows = (flow_table.hie_group == flow_hie_group);
                    group_size(j) = sum(flow_table{flow_rows, {'bytes'}});
                end
            end
            
            %{
            for j = 1:length(groupId)
                rows = (flow_table.group == groupId(j));
                flow_hie_group = unique(flow_table.hie_group(rows));

                if flow_hie_group == -1
                    group_size(j) = sum(flow_table{rows, {'bytes'}});
                else
                    flow_rows = (flow_table.hie_group == flow_hie_group);
                    flow_group = unique(flow_table.group(flow_rows));

                    rows = ismember(flow_group, groupId);
                    if any(~rows)
                        remove_list = [remove_list, j];
                        has_group = [has_group, flow_hie_group];
                    else
                        rows = ismember(groupId, flow_group);
                        hie_group_list(rows) = flow_hie_group;
                        group_size(rows) = sum(flow_table{flow_rows, {'bytes'}});
                    end
                end
            end
            %}
            
            %has_group = unique(has_group);
            %groupId(remove_list) = [];
            %hie_group_list(remove_list) = [];
            %group_size(remove_list) = [];

            
            %{
            group_size_ = [];
            for j = 1:length(groupId)
                rows = (flow_table.group == groupId(j));
                group_size_(j) = sum(flow_table{rows, {'bytes'}});
            end
            %}

            sort_group_size = unique(group_size(:));

            if length(sort_group_size) < 2
                break;
            end

            rows = ismember(group_size, sort_group_size(1:2));
            merge_group = groupId(rows);
            merge_group_hie_id = hie_group_list(rows);
            
            a = hie_group_list(~rows);
            group_num = length(find(a == -1)) + length(unique(a(a ~= -1))) + 1 + length(has_group);
            
            if unique(merge_group_hie_id) == -1
                flow_rows = ismember(flow_table.group, merge_group);
            else
                rows = (merge_group_hie_id == -1);
                flow_rows = ismember(flow_table.group, merge_group(rows)) | ismember(flow_table.hie_group, merge_group_hie_id(~rows));
            end

            srcip_filter = flow_table{flow_rows, {'srcip'}};
            dstip_filter = flow_table{flow_rows, {'dstip'}};

            src_host_filter = cellfun(@(x) host_ip{strcmp(host_ip.IP, x), {'Host'}}, srcip_filter);
            edge_sw_filter = cellfun(@(x) link_if{strcmp(link_if.Src_Node, x), {'Dst_Node'}}, src_host_filter);
            src_edge_sw_filter = unique(edge_sw_filter);

            dst_host_filter = cellfun(@(x) host_ip{strcmp(host_ip.IP, x), {'Host'}}, dstip_filter);
            edge_sw_filter = cellfun(@(x) link_if{strcmp(link_if.Src_Node, x), {'Dst_Node'}}, dst_host_filter);
            dst_edge_sw_filter = unique(edge_sw_filter);

            if length(src_edge_sw_filter) == 1 && length(dst_edge_sw_filter) == 1
                middle_src_sw = src_edge_sw_filter;
                middle_dst_sw = dst_edge_sw_filter;
            else
                if length(src_edge_sw_filter) == 1
                    middle_src_sw = src_edge_sw_filter;
                else
                    middle_src_sw = find_middle_sw(src_edge_sw_filter, g, sw_vector);
                end

                if length(dst_edge_sw_filter) == 1
                    middle_dst_sw = dst_edge_sw_filter;
                else
                    middle_dst_sw = find_middle_sw(dst_edge_sw_filter, g, sw_vector);
                end
            end

            flow_table.middle_src_sw(flow_rows) = {middle_src_sw};
            flow_table.middle_dst_sw(flow_rows) = {middle_dst_sw};

            srcip_filter = cellfun(@(x) strsplit(x, '.'), srcip_filter, 'UniformOutput', false);
            src_subnet = cellfun(@(x) strcat(dec2bin(str2num(x{1}), 8), dec2bin(str2num(x{2}), 8)), srcip_filter, 'UniformOutput', false);
            src_subnet = unique(src_subnet);

            dstip_filter = cellfun(@(x) strsplit(x, '.'), dstip_filter, 'UniformOutput', false);
            dst_subnet = cellfun(@(x) strcat(dec2bin(str2num(x{1}), 8), dec2bin(str2num(x{2}), 8)), dstip_filter, 'UniformOutput', false);
            dst_subnet = unique(dst_subnet);

            if length(src_subnet) == 1
                result_src_subnet = ~xor(logical(src_subnet{1}-'0'), logical(src_subnet{1}-'0'));
            else
                result_src_subnet = ~xor(logical(src_subnet{1}-'0'), logical(src_subnet{2}-'0'));
            end

            src_first_zero = find(result_src_subnet == 0, 1);

            if isempty(src_first_zero)
                src_first_zero = length(result_src_subnet) + 1;
            end

            if length(dst_subnet) == 1
                result_dst_subnet = ~xor(logical(dst_subnet{1}-'0'), logical(dst_subnet{1}-'0'));
            else
                result_dst_subnet = ~xor(logical(dst_subnet{1}-'0'), logical(dst_subnet{2}-'0'));
            end

            dst_first_zero = find(result_dst_subnet == 0, 1);

            if isempty(dst_first_zero)
                dst_first_zero = length(result_dst_subnet) + 1;
            end

            flow_table.hie_prefix(flow_rows) = min(src_first_zero, dst_first_zero) - 1;

            hie_group_id = max(flow_table.hie_group) + 1;
            flow_table.hie_group(flow_rows) = hie_group_id;
        end
    end
end

function middle_sw = find_middle_sw(edge_sw, g, sw_vector)
    middle_sw = -1;
    distance = 1;
    
    nodeNum = findnode(g, edge_sw);
    while middle_sw == -1
        for k = 1:length(nodeNum)
            tmp_list{k} = find(ismember(sw_vector(nodeNum(k), :), (1:distance)));
        end
        
        merge_node = intersect(tmp_list{1}, tmp_list{2});
        for k = 3:length(tmp_list)
            merge_node = intersect(merge_node, tmp_list{k});
        end
        
        if ~isempty(merge_node)
            middle_sw = g.Nodes.Name{merge_node(1)};
        end
        
        distance = distance + 1;
    end
end