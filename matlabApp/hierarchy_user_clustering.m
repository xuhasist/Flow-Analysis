function hierarchy_cluster = hierarchy_user_clustering(g, flow_table, edge_subnet, sw_vector, host_ip, link_if)
    flow_begin_time = datetime(flow_table.start_date_time{1}, 'Format', 'yyyy-MM-dd HH:mm:ss.SSS');
    flow_end_time = datetime(flow_table.end_date_time{end}, 'Format', 'yyyy-MM-dd HH:mm:ss.SSS');
    
    duration = seconds(flow_end_time - flow_begin_time);
    duration = duration / 3;
    
    DateTimeStrings = [];
    DateTimeStrings = [DateTimeStrings, flow_begin_time];
    for i = 1:(3-1)
        flow_begin_time = flow_begin_time + seconds(duration);
        DateTimeStrings = [DateTimeStrings, flow_begin_time];
        DateTimeStrings = [DateTimeStrings, flow_begin_time];
    end
    
    DateTimeStrings = [DateTimeStrings, flow_end_time];  
    
    count = 1;
    hierarchy_cluster = table();
    for i = 1:2:length(DateTimeStrings)
        flow_rows = flow_table.start_date_time >= DateTimeStrings(i) & flow_table.start_date_time < DateTimeStrings(i+1);
        group = flow_table(flow_rows, :);
        
        src_subnet = group.srcip;
        src_subnet = cellfun(@(x) strsplit(x, '.'), src_subnet, 'UniformOutput', false);
        src_subnet = cellfun(@(x) strcat(dec2bin(str2num(x{1}), 8), dec2bin(str2num(x{2}), 8)), src_subnet, 'UniformOutput', false);
        
        dst_subnet = group.dstip;
        dst_subnet = cellfun(@(x) strsplit(x, '.'), dst_subnet, 'UniformOutput', false);
        dst_subnet = cellfun(@(x) strcat(dec2bin(str2num(x{1}), 8), dec2bin(str2num(x{2}), 8)), dst_subnet, 'UniformOutput', false);
        
        flow_subnet_table = table(src_subnet, dst_subnet);
        flow_subnet_table.Properties.VariableNames = {'src_subnet', 'dst_subnet'};
        
        flow_table_start_index = find(flow_rows, 1);
        
        cluster_bit = 16;

        hierarchy_cluster = [hierarchy_cluster table(repmat(cluster_bit, size(flow_table, 1), 1))];
        hierarchy_cluster.Properties.VariableNames{end} = strcat('Prefix_', num2str(cluster_bit));

        subnet_set = cellfun(@(x) x(1:cluster_bit), src_subnet, 'UniformOutput', false);
        subnet_set = [subnet_set, cellfun(@(x) x(1:cluster_bit), dst_subnet, 'UniformOutput', false)];
        
        [~, idx] = unique(cell2mat(subnet_set), 'rows');
        subnet_set = subnet_set(idx,:);
        
        merge_sw_table = cell2table(subnet_set);
        for j = 1:length(subnet_set)
            flow_rows = contains(flow_subnet_table.src_subnet, subnet_set{j, 1}) & contains(flow_subnet_table.dst_subnet, subnet_set{j, 2});
            temp_table = table(find(flow_rows));
            temp_table.Properties.VariableNames = {'flow_index'};

            srcip_filter = group{flow_rows, {'srcip'}};
            dstip_filter = group{flow_rows, {'dstip'}};

            temp_table.srcip = srcip_filter;
            temp_table.dstip = dstip_filter;

            src_host_filter = cellfun(@(x) host_ip{strcmp(host_ip.IP, x), {'Host'}}, srcip_filter);
            edge_sw_filter = cellfun(@(x) link_if{strcmp(link_if.Src_Node, x), {'Dst_Node'}}, src_host_filter);
            src_edge_sw_filter = unique(edge_sw_filter);

            temp_table.srcEdgeSw = edge_sw_filter;

            dst_host_filter = cellfun(@(x) host_ip{strcmp(host_ip.IP, x), {'Host'}}, dstip_filter);
            edge_sw_filter = cellfun(@(x) link_if{strcmp(link_if.Src_Node, x), {'Dst_Node'}}, dst_host_filter);
            dst_edge_sw_filter = unique(edge_sw_filter);

            temp_table.dstEdgeSw = edge_sw_filter;

            if length(src_edge_sw_filter) == 1 && length(dst_edge_sw_filter) == 1
                middle_src_sw = src_edge_sw_filter;
                middle_dst_sw = dst_edge_sw_filter;

                temp_table.srcMiddleSw(:) = middle_src_sw;
                temp_table.dstMiddleSw(:) = middle_dst_sw;
            else
                if length(src_edge_sw_filter) == 1
                    middle_src_sw = src_edge_sw_filter;
                    temp_table.srcMiddleSw(:) = middle_src_sw;
                else
                    if length(src_edge_sw_filter) > 2
                        'QQ'
                    end
                    [merge_sw, middle_sw] = find_middle_sw(src_edge_sw_filter, g, sw_vector);

                    for k = 1:size(merge_sw,1)
                        rows = ismember(temp_table.srcEdgeSw, merge_sw(k,:));
                        temp_table.srcMiddleSw(rows) = middle_sw(k);
                    end
                end

                if length(dst_edge_sw_filter) == 1
                    middle_dst_sw = dst_edge_sw_filter;
                    temp_table.dstMiddleSw(:) = middle_dst_sw;
                else
                    if length(dst_edge_sw_filter) > 2
                        'QQ'
                    end
                    [merge_sw, middle_sw] = find_middle_sw(dst_edge_sw_filter, g, sw_vector);

                    for k = 1:size(merge_sw,1)
                        rows = ismember(temp_table.dstEdgeSw, merge_sw(k,:));
                        temp_table.dstMiddleSw(rows) = middle_sw(k);
                    end
                end
            end

            hierarchy_cluster.Middle_src_sw(find(flow_rows) + flow_table_start_index - 1) = temp_table.srcMiddleSw;
            hierarchy_cluster.Middle_dst_sw(find(flow_rows) + flow_table_start_index - 1) = temp_table.dstMiddleSw;
            
            
            merge_sw_table.srcSw(j) = unique(temp_table.srcMiddleSw);
            merge_sw_table.dstSw(j) = unique(temp_table.dstMiddleSw);
        end
        
        hierarchy_cluster.Properties.VariableNames{end-1} = strcat('Middle_src_sw_', num2str(cluster_bit));
        hierarchy_cluster.Properties.VariableNames{end} = strcat('Middle_dst_sw_', num2str(cluster_bit));

        while cluster_bit > 1
            cluster_bit = cluster_bit - 1;
            
            hierarchy_cluster = [hierarchy_cluster table(repmat(cluster_bit, size(flow_table, 1), 1))];
            hierarchy_cluster.Properties.VariableNames{end} = strcat('Prefix_', num2str(cluster_bit));
            
            subnet_set = cellfun(@(x) x(1:cluster_bit), merge_sw_table.subnet_set1, 'UniformOutput', false);
            subnet_set = [subnet_set, cellfun(@(x) x(1:cluster_bit), merge_sw_table.subnet_set2, 'UniformOutput', false)];

            [~, idx] = unique(cell2mat(subnet_set), 'rows');
            subnet_set = subnet_set(idx,:);
            
            merge_sw_table_new = cell2table(subnet_set);
            
            for j = 1:length(subnet_set)
                flow_rows = contains(merge_sw_table.subnet_set1, subnet_set{j, 1}) & contains(merge_sw_table.subnet_set2, subnet_set{j, 2});
                temp_table = table(find(flow_rows));
                temp_table.Properties.VariableNames = {'flow_index'};
                
                edge_sw_filter = merge_sw_table{flow_rows, {'srcSw'}};
                src_edge_sw_filter = unique(edge_sw_filter);

                temp_table.srcEdgeSw = edge_sw_filter;
                
                edge_sw_filter = merge_sw_table{flow_rows, {'dstSw'}};
                dst_edge_sw_filter = unique(edge_sw_filter);

                temp_table.dstEdgeSw = edge_sw_filter;
                
                if length(src_edge_sw_filter) == 1 && length(dst_edge_sw_filter) == 1
                    middle_src_sw = src_edge_sw_filter;
                    middle_dst_sw = dst_edge_sw_filter;

                    temp_table.srcMiddleSw(:) = middle_src_sw;
                    temp_table.dstMiddleSw(:) = middle_dst_sw;
                else
                    if length(src_edge_sw_filter) == 1
                        middle_src_sw = src_edge_sw_filter;
                        temp_table.srcMiddleSw(:) = middle_src_sw;
                    else
                        if length(src_edge_sw_filter) > 2
                            'QQ'
                        end
                        [merge_sw, middle_sw] = find_middle_sw(src_edge_sw_filter, g, sw_vector);

                        for k = 1:size(merge_sw,1)
                            rows = ismember(temp_table.srcEdgeSw, merge_sw(k,:));
                            temp_table.srcMiddleSw(rows) = middle_sw(k);
                        end
                    end

                    if length(dst_edge_sw_filter) == 1
                        middle_dst_sw = dst_edge_sw_filter;
                        temp_table.dstMiddleSw(:) = middle_dst_sw;
                    else
                        if length(dst_edge_sw_filter) > 2
                            'QQ'
                        end
                        [merge_sw, middle_sw] = find_middle_sw(dst_edge_sw_filter, g, sw_vector);

                        for k = 1:size(merge_sw,1)
                            rows = ismember(temp_table.dstEdgeSw, merge_sw(k,:));
                            temp_table.dstMiddleSw(rows) = middle_sw(k);
                        end
                    end
                end
                
                x = temp_table{:, {'srcEdgeSw', 'dstEdgeSw'}};
                flow_rows = [];
                for k = 1:size(x,1)
                    flow_rows = find(strcmp(hierarchy_cluster{:, strcat('Middle_src_sw_', num2str(cluster_bit+1))}, x(k, 1)) & strcmp(hierarchy_cluster{:, strcat('Middle_dst_sw_', num2str(cluster_bit+1))}, x(k, 2)));
                
                    hierarchy_cluster.Middle_src_sw(flow_rows + flow_table_start_index - 1) = temp_table.srcMiddleSw(k);
                    hierarchy_cluster.Middle_dst_sw(flow_rows + flow_table_start_index - 1) = temp_table.dstMiddleSw(k);
                end
                
                merge_sw_table_new.srcSw(j) = unique(temp_table.srcMiddleSw);
                merge_sw_table_new.dstSw(j) = unique(temp_table.dstMiddleSw);
            end
            
            hierarchy_cluster.Properties.VariableNames{end-1} = strcat('Middle_src_sw_', num2str(cluster_bit));
            hierarchy_cluster.Properties.VariableNames{end} = strcat('Middle_dst_sw_', num2str(cluster_bit));
            
            merge_sw_table = merge_sw_table_new;
        end
    end
end

function [merge_sw, middle_sw] = find_middle_sw(edge_sw, g, sw_vector)
    distance = 1;
    merge_sw = {};
    middle_sw = [];
    
    while length(edge_sw) > 1
        nodeNum = findnode(g, edge_sw);
        for k = 1:length(nodeNum)
            tmp_list{k} = find(ismember(sw_vector(nodeNum(k), :), (1:distance)));
        end

        A = [tmp_list{:}];
        [uniqueA m n] = unique(A,'first');
        indexToDupes = find(not(ismember(1:numel(A),m)));
        
        for i = 1:indexToDupes
            rows = cellfun(@(x) any(ismember(x, A(indexToDupes(i)))), tmp_list);
            
            tmp_list(rows) = [];
            edge_sw(rows) = [];
            
            merge_sw = [merge_sw; g.Nodes.Name(nodeNum(rows))'];
            middle_sw = [middle_sw; g.Nodes.Name(A(indexToDupes(i)))];
            
            if isempty(tmp_list) 
                break;
            end
        end
        
        distance = distance + 1;
    end
end