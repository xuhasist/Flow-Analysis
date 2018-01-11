function hierarchy_table = hierarchical(g, hierarchy_table, prefix_length, sw_vector, host_ip, link_if, flow_table, i)
    DateStrings = {'2009-12-18 00:26', '2009-12-18 00:48'; '2009-12-18 00:48', '2009-12-18 01:10'; '2009-12-18 01:10', '2009-12-18 01:32'};
    t = datetime(DateStrings,'InputFormat','yyyy-MM-dd HH:mm');
    
    flow_table_start_date_time = datetime(flow_table.start_date_time(i:end), 'Format', 'yyyy-MM-dd HH:mm:ss.SSS');
    flow_table_end_date_time = datetime(flow_table.end_date_time(i:end), 'Format', 'yyyy-MM-dd HH:mm:ss.SSS');
    
    flow_table_start_index = i;
    
    for i = 1:length(t)
        start_time = t(i,1);
        end_time = t(i,2);
        
        flowIndex = ((flow_table_start_date_time >= start_time) & (flow_table_start_date_time < end_time)) | ((flow_table_end_date_time >= start_time) & (flow_table_end_date_time <end_time));
        cluster = flow_table(find(flowIndex) + flow_table_start_index - 1, :);
        
        src_subnet = cluster.srcip;
        src_subnet = cellfun(@(x) strsplit(x, '.'), src_subnet, 'UniformOutput', false);
        src_subnet = cellfun(@(x) strcat(dec2bin(str2num(x{1}), 8), dec2bin(str2num(x{2}), 8)), src_subnet, 'UniformOutput', false);

        dst_subnet = cluster.dstip;
        dst_subnet = cellfun(@(x) strsplit(x, '.'), dst_subnet, 'UniformOutput', false);
        dst_subnet = cellfun(@(x) strcat(dec2bin(str2num(x{1}), 8), dec2bin(str2num(x{2}), 8)), dst_subnet, 'UniformOutput', false);

        subnet_set = cellfun(@(x) x(1:prefix_length), src_subnet, 'UniformOutput', false);
        subnet_set = [subnet_set, cellfun(@(x) x(1:prefix_length), dst_subnet, 'UniformOutput', false)];
        [~, idx] = unique(cell2mat(subnet_set), 'rows');
        subnet_set = subnet_set(idx,:);
        
        flow_subnet_table = table(find(flowIndex) + flow_table_start_index - 1, src_subnet, dst_subnet);
        flow_subnet_table.Properties.VariableNames = {'flow_index', 'src_subnet', 'dst_subnet'};
        
        for j = 1:size(subnet_set, 1)
            flow_rows = startsWith(flow_subnet_table.src_subnet, subnet_set{j, 1}) & startsWith(flow_subnet_table.dst_subnet, subnet_set{j, 2});
        
            %srcip_filter = flow_table{find(flow_rows) + flow_table_start_index - 1, {'srcip'}};
            %dstip_filter = flow_table{find(flow_rows) + flow_table_start_index - 1, {'dstip'}};
            
            srcip_filter = cluster{flow_rows, {'srcip'}};
            dstip_filter = cluster{flow_rows, {'dstip'}};
            
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
            
            index = flow_subnet_table.flow_index(flow_rows);
            
            hierarchy_table.middle_src_sw(index) = {middle_src_sw};
            hierarchy_table.middle_dst_sw(index) = {middle_dst_sw};
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