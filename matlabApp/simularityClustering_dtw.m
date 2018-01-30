function flow_table = simularityClustering_dtw(g, host_ip, link_if, flow_table, sequence)
    %{
    start_time = datetime('2009-12-18 00:26', 'InputFormat', 'yyyy-MM-dd HH:mm');
    end_time = datetime('2009-12-18 01:32', 'InputFormat', 'yyyy-MM-dd HH:mm');
    
    slot_num = minutes(end_time - start_time);
    sequence = []; % all flow sequence
    for i = 1:size(flow_table, 1)
        sequence(i,:) = zeros(slot_num, 1);
        
        flow_start_time = datetime(flow_table{i, 'start_date_time'}{1}, 'Format', 'yyyy-MM-dd HH:mm:ss.SSS');
        flow_end_time = datetime(flow_table{i, 'end_date_time'}{1}, 'Format', 'yyyy-MM-dd HH:mm:ss.SSS');
        
        sloc = floor(minutes(flow_start_time - start_time)) + 1;
        eloc = floor(minutes(flow_end_time - start_time)) + 1;
        
        sequence(i, sloc:eloc) = 1;
    end
    %}

    %{
    dtw_list = []; % distance between two flow
    c = 1;
    for i = 1:size(sequence, 1) - 1
        for j = i+1:size(sequence, 1)
            %dtw_list(c).dtw = dtw(sequence(i,:), sequence(j,:));
            dtw_list(c).dtw = sqrt(sum((sequence(i,:) - sequence(j,:)) .^ 2));
            dtw_list(c).flow1 = i;
            dtw_list(c).flow2 = j;
            c = c + 1;
        end
    end
    %}
    
    [idx, group_num] = doKmeans(sequence);
    
    group_index = 1;
    for i = 1:group_num
        group_flow = (idx == i);
        flow_index_filter = find(group_flow);
        
        group_flow = ismember(flow_table.index, flow_index_filter);
        flow_index_filter = find(group_flow);
        
        srcip_filter = flow_table{group_flow, {'srcip'}};
        dstip_filter = flow_table{group_flow, {'dstip'}};

        src_host_filter = cellfun(@(x) host_ip{strcmp(host_ip.IP, x), {'Host'}}, srcip_filter);
        src_edge_sw_filter = cellfun(@(x) link_if{strcmp(link_if.Src_Node, x), {'Dst_Node'}}, src_host_filter);
        src_edge_sw_filter = findnode(g, src_edge_sw_filter);

        dst_host_filter = cellfun(@(x) host_ip{strcmp(host_ip.IP, x), {'Host'}}, dstip_filter);
        dst_edge_sw_filter = cellfun(@(x) link_if{strcmp(link_if.Src_Node, x), {'Dst_Node'}}, dst_host_filter);
        dst_edge_sw_filter = findnode(g, dst_edge_sw_filter);

        sw_pair = [src_edge_sw_filter, dst_edge_sw_filter];
        [~, id] = unique(sw_pair, 'rows');
        unique_sw_pair = sw_pair(id, :);

        for k = 1:size(unique_sw_pair, 1)
            rows = ismember(sw_pair(:,:), unique_sw_pair(k,:), 'rows');
            flow_index = flow_index_filter(rows);

            if length(flow_index) == 1
                flow_table.group(flow_index) = group_index;
                group_index = group_index + 1;
                flow_table.prefix(flow_index) = 32;
            else
                flow_table.group(flow_index) = group_index;
                group_index = group_index + 1;

                % calculate max prefix length
                src_ip = flow_table.srcip(flow_index);
                src_ip = cellfun(@(x) strsplit(x, '.'), src_ip, 'UniformOutput', false);
                src_subnet = cellfun(@(x) strcat(dec2bin(str2num(x{1}), 8), dec2bin(str2num(x{2}), 8), dec2bin(str2num(x{3}), 8), dec2bin(str2num(x{4}), 8)), src_ip, 'UniformOutput', false);

                c = 32;
                for m = 2:length(src_subnet)
                    result_src_subnet = ~xor(logical(src_subnet{m-1}(1:c)-'0'), logical(src_subnet{m}(1:c)-'0'));
                    src_first_zero = find(result_src_subnet == 0, 1);

                    if src_first_zero == 17
                        break;
                    elseif isempty(src_first_zero)
                        src_first_zero = length(result_src_subnet) + 1;
                        continue;
                    else
                        c = src_first_zero - 1;
                    end
                end

                if src_first_zero == 17
                    continue;
                end

                dst_ip = flow_table.dstip(flow_index);
                dst_ip = cellfun(@(x) strsplit(x, '.'), dst_ip, 'UniformOutput', false);
                dst_subnet = cellfun(@(x) strcat(dec2bin(str2num(x{1}), 8), dec2bin(str2num(x{2}), 8), dec2bin(str2num(x{3}), 8), dec2bin(str2num(x{4}), 8)), dst_ip, 'UniformOutput', false);

                c = 32;
                for m = 2:length(dst_subnet)
                    result_dst_subnet = ~xor(logical(dst_subnet{m-1}(1:c)-'0'), logical(dst_subnet{m}(1:c)-'0'));
                    dst_first_zero = find(result_dst_subnet == 0, 1);

                    if dst_first_zero == 17
                        break;
                    elseif isempty(dst_first_zero)
                        dst_first_zero = length(result_dst_subnet) + 1;
                        continue;
                    else
                        c = dst_first_zero - 1;
                    end
                end

                if dst_first_zero == 17
                    continue;
                else
                    flow_table.prefix(flow_index) = min(src_first_zero, dst_first_zero) - 1;
                end
            end
        end
    end
    
    %{
    k = 10; % the number of cluster
    idx = kmeans([dtw_list.dtw]', k);
    
    unique_dtw = sort(unique([dtw_list.dtw]));
    group_index = 1;
    finish_flow = [];
    finish_idx = [];
    for i = 1:length(unique_dtw)
        rows = ([dtw_list.dtw] == unique_dtw(i));
        
        idx_filter = unique(idx(rows));
        
        if length(idx_filter) > 1
            ':)'
        end
        
        rows = ismember(idx_filter, finish_idx);
        idx_filter(rows) = [];
        
        for j = 1:length(idx_filter)
            rows = (idx == idx_filter(j));
            
            group_flow = unique([dtw_list(rows).flow1, dtw_list(rows).flow2]);
            rows = ismember(group_flow, finish_flow);
            group_flow(rows) = [];

            if isempty(group_flow)
                break;
            end
            
            srcip_filter = flow_table{group_flow, {'srcip'}};
            dstip_filter = flow_table{group_flow, {'dstip'}};
            
            src_host_filter = cellfun(@(x) host_ip{strcmp(host_ip.IP, x), {'Host'}}, srcip_filter);
            src_edge_sw_filter = cellfun(@(x) link_if{strcmp(link_if.Src_Node, x), {'Dst_Node'}}, src_host_filter);
            src_edge_sw_filter = findnode(g, src_edge_sw_filter);
            
            dst_host_filter = cellfun(@(x) host_ip{strcmp(host_ip.IP, x), {'Host'}}, dstip_filter);
            dst_edge_sw_filter = cellfun(@(x) link_if{strcmp(link_if.Src_Node, x), {'Dst_Node'}}, dst_host_filter);
            dst_edge_sw_filter = findnode(g, dst_edge_sw_filter);
            
            sw_pair = [src_edge_sw_filter, dst_edge_sw_filter];
            [~, id] = unique(sw_pair, 'rows');
            unique_sw_pair = sw_pair(id, :);
            
            for k = 1:size(unique_sw_pair, 1)
                rows = ismember(sw_pair(:,:), unique_sw_pair(k,:), 'rows');
                flow_index = group_flow(rows);
                
                if length(flow_index) == 1
                    flow_table.group(flow_index) = group_index;
                    group_index = group_index + 1;
                    flow_table.prefix(flow_index) = 32;
                    %finish_flow = [finish_flow, flow_index];
                else%if length(flow_index) > 1
                    flow_table.group(flow_index) = group_index;
                    group_index = group_index + 1;
                    finish_flow = [finish_flow, flow_index];
                    
                    % calculate max prefix length
                    src_ip = flow_table.srcip(flow_index);
                    src_ip = cellfun(@(x) strsplit(x, '.'), src_ip, 'UniformOutput', false);
                    src_subnet = cellfun(@(x) strcat(dec2bin(str2num(x{1}), 8), dec2bin(str2num(x{2}), 8), dec2bin(str2num(x{3}), 8), dec2bin(str2num(x{4}), 8)), src_ip, 'UniformOutput', false);
                    
                    c = 32;
                    for m = 2:length(src_subnet)
                        result_src_subnet = ~xor(logical(src_subnet{m-1}(1:c)-'0'), logical(src_subnet{m}(1:c)-'0'));
                        src_first_zero = find(result_src_subnet == 0, 1);
                        
                        if src_first_zero == 17
                            break;
                        elseif isempty(src_first_zero)
                            src_first_zero = length(result_src_subnet) + 1;
                            continue;
                        else
                            c = src_first_zero - 1;
                        end
                    end
                    
                    if src_first_zero == 17
                        continue;
                    end
                    
                    dst_ip = flow_table.dstip(flow_index);
                    dst_ip = cellfun(@(x) strsplit(x, '.'), dst_ip, 'UniformOutput', false);
                    dst_subnet = cellfun(@(x) strcat(dec2bin(str2num(x{1}), 8), dec2bin(str2num(x{2}), 8), dec2bin(str2num(x{3}), 8), dec2bin(str2num(x{4}), 8)), dst_ip, 'UniformOutput', false);
                    
                    c = 32;
                    for m = 2:length(dst_subnet)
                        result_dst_subnet = ~xor(logical(dst_subnet{m-1}(1:c)-'0'), logical(dst_subnet{m}(1:c)-'0'));
                        dst_first_zero = find(result_dst_subnet == 0, 1);
                        
                        if dst_first_zero == 17
                            break;
                        elseif isempty(dst_first_zero)
                            dst_first_zero = length(result_dst_subnet) + 1;
                            continue;
                        else
                            c = dst_first_zero - 1;
                        end
                    end
                    
                    if dst_first_zero == 17
                        continue;
                    else
                        flow_table.prefix(flow_index) = min(src_first_zero, dst_first_zero) - 1;
                    end
                end
            end
        end
        finish_idx = [finish_idx, idx_filter];
    end
    %}
end

function [idx, k] = doKmeans(sequence)
    k = 0;
    pre_avg_dist = -1;
    avg_dist = -1;
    
    while pre_avg_dist == -1 || ~(avg_dist >= pre_avg_dist * (95/100) && avg_dist <= pre_avg_dist)
        k = k + 1;
        pre_avg_dist = avg_dist;
        
        [idx, C, sumd] = kmeans(sequence, k);
        
        avg_sumd = [];
        for i = 1:length(sumd)
            avg_sumd(i) = (sumd(i) / length(idx(idx == i)));
        end
        avg_dist = (sum(avg_sumd) / length(sumd));
    end
end