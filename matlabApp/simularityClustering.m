function flow_table = simularityClustering(prefix_length, host_ip, link_if, flow_table, i)
    DateStrings = {'2009-12-18 00:26', '2009-12-18 00:48'; '2009-12-18 00:48', '2009-12-18 01:10'; '2009-12-18 01:10', '2009-12-18 01:32'};
    t = datetime(DateStrings,'InputFormat','yyyy-MM-dd HH:mm');
    
    flow_table_start_date_time = datetime(flow_table.start_date_time(i:end), 'Format', 'yyyy-MM-dd HH:mm:ss.SSS');
    flow_table_end_date_time = datetime(flow_table.end_date_time(i:end), 'Format', 'yyyy-MM-dd HH:mm:ss.SSS');
    
    flow_table_start_index = i;
    
    for i = 1:length(t)
        start_time = t(i,1);
        end_time = t(i,2);

        flowIndex = ((flow_table_start_date_time >= start_time) & (flow_table_start_date_time < end_time)) | ((flow_table_end_date_time >= start_time) & (flow_table_end_date_time < end_time));
        cluster = flow_table(find(flowIndex) + flow_table_start_index - 1, :);
        
        src_subnet = cluster.srcip;
        src_subnet = cellfun(@(x) strsplit(x, '.'), src_subnet, 'UniformOutput', false);
        src_subnet = cellfun(@(x) strcat(dec2bin(str2num(x{1}), 8), dec2bin(str2num(x{2}), 8), dec2bin(str2num(x{3}), 8), dec2bin(str2num(x{4}), 8)), src_subnet, 'UniformOutput', false);

        dst_subnet = cluster.dstip;
        dst_subnet = cellfun(@(x) strsplit(x, '.'), dst_subnet, 'UniformOutput', false);
        dst_subnet = cellfun(@(x) strcat(dec2bin(str2num(x{1}), 8), dec2bin(str2num(x{2}), 8), dec2bin(str2num(x{3}), 8), dec2bin(str2num(x{4}), 8)), dst_subnet, 'UniformOutput', false);

        subnet_set = cellfun(@(x) x(1:prefix_length), src_subnet, 'UniformOutput', false);
        subnet_set = [subnet_set, cellfun(@(x) x(1:prefix_length), dst_subnet, 'UniformOutput', false)];
        [~, idx] = unique(cell2mat(subnet_set), 'rows');
        subnet_set = subnet_set(idx,:);
        
        flow_subnet_table = table(find(flowIndex) + flow_table_start_index - 1, src_subnet, dst_subnet);
        flow_subnet_table.Properties.VariableNames = {'flow_index', 'src_subnet', 'dst_subnet'};
        
        group_index = 1;
        for j = 1:size(subnet_set, 1)
            flow_rows = startsWith(flow_subnet_table.src_subnet, subnet_set{j, 1}) & startsWith(flow_subnet_table.dst_subnet, subnet_set{j, 2});
        
            if length(find(flow_rows)) == 1
                continue
            end
            
            srcip_filter = cluster{flow_rows, {'srcip'}};
            dstip_filter = cluster{flow_rows, {'dstip'}};

            src_host_filter = cellfun(@(x) host_ip{strcmp(host_ip.IP, x), {'Host'}}, srcip_filter);
            edge_sw_filter = cellfun(@(x) link_if{strcmp(link_if.Src_Node, x), {'Dst_Node'}}, src_host_filter);
            src_edge_sw_filter = unique(edge_sw_filter);

            dst_host_filter = cellfun(@(x) host_ip{strcmp(host_ip.IP, x), {'Host'}}, dstip_filter);
            edge_sw_filter = cellfun(@(x) link_if{strcmp(link_if.Src_Node, x), {'Dst_Node'}}, dst_host_filter);
            dst_edge_sw_filter = unique(edge_sw_filter);
            
            % user cross edge switch, ignore
            if length(src_edge_sw_filter) > 1 || length(dst_edge_sw_filter) > 1
                continue
            else
                index = flow_subnet_table.flow_index(flow_rows);
                temp = flow_table.group(index);
                temp = cellfun(@(x) [x group_index], temp, 'UniformOutput', false);
                
                flow_table.group(index) = temp;
                group_index = group_index + 1;
            end
        end
    end
end