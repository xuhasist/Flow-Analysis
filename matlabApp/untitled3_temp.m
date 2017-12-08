
%{ 
calculate link bandwidth not finish
    length = flow_table{i,'length'}(1) / 1000;
    start_time = datetime(flow_entry.start_time, 'Format', 'yyyy-MM-dd HH:mm:ss.SSS');
    end_time = datetime(flow_entry.end_time, 'Format', 'yyyy-MM-dd HH:mm:ss.SSS');
    duration = second(end_time) - second(start_time);
    bwd = length / duration;
%}

%{
%size(flow_table, 1)
for i = 1:size(flow_table, 1)
    i
    src_name = host_ip{flow_table{i,'srcip'}{1}, 'Host'}{1};
    dst_name = host_ip{flow_table{i,'dstip'}{1}, 'Host'}{1};
    path = shortestpath(g, src_name, dst_name, 'Method', 'positive');
    if isempty(path)
       continue
    end

    flow_entry = struct();
    flow_entry.start_time = flow_table{i, 'start_date_time'}{1};
    %flow_entry.end_time = flow_table{i, 'end_date_time'}{1};
    flow_entry.end_time = datestr(datetime(flow_table{i, 'end_date_time'}{1}, 'Format', 'yyyy-MM-dd HH:mm:ss.SSS') + seconds(60), 'yyyy-mm-dd HH:MM:ss.FFF');
    flow_entry.src_ip = flow_table{i, 'srcip'}{1};
    flow_entry.dst_ip = flow_table{i,'dstip'}{1};
    flow_entry.src_port = flow_table{i, 'srcport'}(1);
    flow_entry.dst_port = flow_table{i, 'dstport'}(1);
    flow_entry.protocol = flow_table{i, 'protocol'}{1};

    j = 2;
    sw = findnode(g, path{j});
    no_exist = true;
    while sw ~= findnode(g, path{length(path)})
        if no_exist
            rows = strcmp(link_if.Src_Node, path{j-1}) & strcmp(link_if.Dst_Node, path{j});
            flow_entry.input = link_if(rows, {'Dst_Inf'}).(1);

            rows = strcmp(link_if.Src_Node, path{j}) & strcmp(link_if.Dst_Node, path{j+1});
            flow_entry.output = link_if(rows, {'Src_Inf'}).(1);   
        else
            no_exist = true;
        end     

        if isempty(sw_struct(sw).entry)
            sw_struct(sw).entry = flow_entry;
            j = j + 1;
            sw = findnode(g, path{j});
        else
            flow_compare = arrayfun(@(x) isequal(flow_entry.src_ip, x.src_ip) & isequal(flow_entry.dst_ip, x.dst_ip) & isequal(flow_entry.src_port, x.src_port) & isequal(flow_entry.dst_port, x.dst_port) & isequal(flow_entry.protocol, x.protocol) & isequal(flow_entry.input, x.input), sw_struct(sw).entry);
            if ~any(flow_compare)
                k_ = length(sw_struct(sw).entry);
                sw_struct(sw).entry(k_+1) = flow_entry;
                j = j + 1;
                sw = findnode(g, path{j});
            else
                same_flow_loc = find(flow_compare == 1);
                same_flow_loc = same_flow_loc(end);
                old_flow_e_time = datetime(sw_struct(sw).entry(same_flow_loc).end_time, 'Format', 'yyyy-MM-dd HH:mm:ss.SSS');
                new_flow_s_time = datetime(flow_entry.start_time, 'Format', 'yyyy-MM-dd HH:mm:ss.SSS');
                new_flow_e_time = datetime(flow_entry.end_time, 'Format', 'yyyy-MM-dd HH:mm:ss.SSS');
                if new_flow_s_time - old_flow_e_time > seconds(60)
                    k_ = length(sw_struct(sw).entry);
                    sw_struct(sw).entry(k_+1) = flow_entry;
                    j = j + 1;
                    sw = findnode(g, path{j});
                else
                    sw_struct(sw).entry(same_flow_loc).end_time = datestr(max(old_flow_e_time, new_flow_e_time) + seconds(60), 'yyyy-mm-dd HH:MM:ss.FFF');
                    
                    %rows = strcmp(link_if.Src_Node, nodeName{sw}) & strcmp(link_if.Src_Inf, sw_struct(sw).entry(same_flow_loc).output);
                    rows = strcmp(link_if.Src_Node, nodeName{sw}) & (link_if.Src_Inf == sw_struct(sw).entry(same_flow_loc).output);
                    sw = findnode(g, link_if(rows, {'Dst_Node'}).(1));
                    
                    rows = strcmp(link_if.Src_Node, path{j-1}) & strcmp(link_if.Dst_Node, path{j});
                    flow_entry.input = link_if(rows, {'Dst_Inf'}).(1);
                    
                    no_exist = false;
                end
            end
        end
    end
end
%}
%{
%size(flow_table, 1)
for i = 1:size(flow_table, 1)
    i
    src_name = host_ip{flow_table{i,'srcip'}{1}, 'Host'}{1};
    dst_name = host_ip{flow_table{i,'dstip'}{1}, 'Host'}{1};
    path = shortestpath(g, src_name, dst_name, 'Method', 'positive');
    if isempty(path)
        continue
    end

    flow_entry = struct();
    flow_entry.start_time = flow_table{i, 'start_date_time'}{1};
    flow_entry.end_time = flow_table{i, 'end_date_time'}{1};
    sip = strsplit(flow_table{i, 'srcip'}{1}, '.');
    dip = strsplit(flow_table{i, 'dstip'}{1}, '.');

    if group(i) == 1
        flow_entry.src_ip = [sip{1}, '.0.0.0'];
        flow_entry.dst_ip = [dip{1}, '.0.0.0'];
    elseif group(i) == 2
        flow_entry.src_ip = [sip{1}, '.', sip{2}, '.0.0'];
        flow_entry.dst_ip = [dip{1}, '.', dip{2}, '.0.0'];
    elseif group(i) == 3
        flow_entry.src_ip = [sip{1}, '.', sip{2}, '.', sip{3}, '.0'];
        flow_entry.dst_ip = [dip{1}, '.', dip{2}, '.', dip{3}, '.0'];
    else
        flow_entry.src_ip = flow_table{i, 'srcip'}{1};
        flow_entry.dst_ip = flow_table{i, 'dstip'}{1};
    end

    flow_entry.protocol = flow_table{i, 'protocol'}{1};

    j = 2;
    sw = findnode(g, path{j});
    no_exist = true;
    while sw ~= findnode(g, path{length(path)})
        if no_exist
            rows = strcmp(link_if.Src_Node, path{j-1}) & strcmp(link_if.Dst_Node, path{j});
            flow_entry.input = link_if(rows, {'Dst_Inf'}).(1);

            rows = strcmp(link_if.Src_Node, path{j}) & strcmp(link_if.Dst_Node, path{j+1});
            flow_entry.output = link_if(rows, {'Src_Inf'}).(1);
        else
            no_exist = true;
        end 

        if isempty(sw_struct(sw).entry)
            sw_struct(sw).entry = flow_entry;
            j = j + 1;
            sw = findnode(g, path{j});
        else
            flow_compare = arrayfun(@(x) isequal(flow_entry.src_ip, x.src_ip) & isequal(flow_entry.dst_ip, x.dst_ip) & isequal(flow_entry.protocol, x.protocol) & isequal(flow_entry.input, x.input), sw_struct(sw).entry);
            if ~any(flow_compare)
                k_ = length(sw_struct(sw).entry);
                sw_struct(sw).entry(k_+1) = flow_entry;
                j = j + 1;
                sw = findnode(g, path{j});
            else
                same_flow_loc = find(flow_compare == 1);
                same_flow_loc = same_flow_loc(end);
                old_flow_e_time = datetime(sw_struct(sw).entry(same_flow_loc).end_time, 'Format', 'yyyy-MM-dd HH:mm:ss.SSS');
                new_flow_s_time = datetime(flow_entry.start_time, 'Format', 'yyyy-MM-dd HH:mm:ss.SSS');
                new_flow_e_time = datetime(flow_entry.end_time, 'Format', 'yyyy-MM-dd HH:mm:ss.SSS');
                if new_flow_s_time - old_flow_e_time > seconds(60)
                    k_ = length(sw_struct(sw).entry);
                    sw_struct(sw).entry(k_+1) = flow_entry;
                    j = j + 1;
                    sw = findnode(g, path{j});
                else
                    sw_struct(sw).entry(same_flow_loc).end_time = datestr(max(old_flow_e_time, new_flow_e_time), 'yyyy-mm-dd HH:MM:ss.FFF');

                    rows = strcmp(link_if.Src_Node, nodeName{sw}) & strcmp(link_if.Src_Inf, sw_struct(sw).entry(same_flow_loc).output);
                    sw = findnode(g, link_if(rows, {'Dst_Node'}).(1));
                    
                    no_exist = false;
                end
            end
        end
    end
end
%}