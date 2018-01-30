clearvars

global current_flow_time

t1 = datetime('now');

host_x = 15;
host_sd = 3;

% fat tree
k = 4;
[sw_number, srcNode, dstNode, srcInf, dstInf, g, edge_subnet, host_at_sw, hostNum, IP] = ...
    createFatTreeTopo_mod(k, host_x, host_sd);

% AS_topo
%as_edge_sw_num = 5;
%[sw_number, srcNode, dstNode, srcInf, dstInf, g, asNum, nodeT, edge_subnet, host_at_sw, hostNum, IP] = ...
%    createAsTopo_mod(as_edge_sw_num, host_x, host_sd);

flowNum = 5000;
[link_if, host_ip, sw_struct, link, link_struct, flow_table, sequence] = ...
    setVariables_mod(sw_number, srcNode, dstNode, srcInf, dstInf, g, hostNum, IP, flowNum);

sw_vector = distances(g, 'Method', 'unweighted');
sw_vector = sw_vector(1:sw_number, 1:sw_number);

% for as topo
%rows = strcmp(nodeT.Type, 'RT_NODE');
%sw_vector(rows, rows) = 0;

link_bwd_unit = 10^3; %10Kbps
flow_final_path = {};
preLower = [];

%{
hierarchy_table = table();
hierarchy_table.group = repmat(-1, size(flow_table, 1), 1);
hierarchy_table.middle_src_sw = repmat({{}}, size(flow_table, 1), 1);
hierarchy_table.middle_dst_sw = repmat({{}}, size(flow_table, 1), 1);
hierarchy_table.prefix = zeros(size(flow_table, 1), 1);
%}

%prefix_length = 16; %bits
%prefix_threshold = 16;

flowEntry_threshold = 20;

has_hierarchy = false;

%{
schedule = timer;
schedule.Period = 10;
schedule.TasksToExecute = inf;
schedule.ExecutionMode = 'fixedRate';
schedule.TimerFcn = {@timerFunction, flowEntry_threshold};
schedule.StartDelay = 10;
%}

%updatePrefixLength = false;

doHierarchical = false;
sw_tooManyFlowEntry = [];

flow_table.group = repmat(-1, size(flow_table, 1), 1);
flow_table.prefix = repmat(16, size(flow_table, 1), 1);
flow_table.hie_group = repmat(-1, size(flow_table, 1), 1);
flow_table.middle_src_sw = repmat({{}}, size(flow_table, 1), 1);
flow_table.middle_dst_sw = repmat({{}}, size(flow_table, 1), 1);
flow_table.hie_prefix = zeros(size(flow_table, 1), 1);

%flow_table = simularityClustering(prefix_length, host_ip, link_if, flow_table, 1);
flow_table = simularityClustering_dtw(g, host_ip, link_if, flow_table, sequence);

hie_count = 0;

flow_table_temp = flow_table;
host_ip_temp = host_ip;
sw_struct_temp = sw_struct;
link_if_temp = link_if;
link_temp = link;
link_struct_temp = link_struct;
sw_vector_temp = sw_vector;

%start(schedule)
pre_check_time = datetime(flow_table{1, 'start_date_time'}{1}, 'Format', 'yyyy-MM-dd HH:mm:ss.SSS');
for i = 1:size(flow_table, 1)
    i
    
    [src_name, dst_name, flow_start_datetime, flow_end_datetime, flow_start_strtime, flow_end_strtime, ...
        flow, flow_table, flow_entry] = setFlowInfo(link_bwd_unit, host_ip, flow_table, i);
    
    current_flow_time = flow_start_datetime;
    
    if current_flow_time - pre_check_time >= seconds(60)
        [doHierarchical, sw_tooManyFlowEntry] = checkFlowTable(flowEntry_threshold, sw_struct, doHierarchical, sw_tooManyFlowEntry);
        pre_check_time = current_flow_time;
    end
    
    rows = strcmp(link_if.Src_Node, src_name);
    src_edge_sw = link_if{rows, {'Dst_Node'}}{1};
    
    rows = strcmp(link_if.Src_Node, dst_name);
    dst_edge_sw = link_if{rows, {'Dst_Node'}}{1};
    
    final_path = findnode(g, src_name);
    final_path_temp = [];
    
    if ~isempty(flow_table.middle_src_sw{i}) || ~isempty(flow_table.middle_dst_sw{i})
        has_hierarchy = true;
    end
    
    if has_hierarchy
        middle_src_sw = flow_table.middle_src_sw{i};
        middle_dst_sw = flow_table.middle_dst_sw{i};
        
        sw_list = {src_edge_sw, middle_src_sw, middle_dst_sw, dst_edge_sw};
        %{sw_list{1}, sw_list{2}, sw_list{3}, sw_list{4}}
        
        prefix_length = flow_table.prefix(i);
        hie_prefix_length = flow_table.hie_prefix(i);
        
        prefix_list = [prefix_length, hie_prefix_length, prefix_length];
       
        for j = 1:length(sw_list) - 1
            first_edge_sw = sw_list{j};
            second_edge_sw = sw_list{j+1};

            flow_entry_temp = setFlowEntry(prefix_list(j), flow_entry, flow_table, i);
            
            if strcmp(first_edge_sw, src_edge_sw)
                rows = strcmp(link_if.Src_Node, src_name);
                flow_entry_temp.input = link_if{rows, {'Dst_Inf'}};
            else
                rows = strcmp(link_if.Src_Node, g.Nodes.Name{final_path(end-1)}) & strcmp(link_if.Dst_Node, g.Nodes.Name{final_path(end)});
                flow_entry_temp.input = link_if{rows, {'Dst_Inf'}};
            end

            flow.dst_name = second_edge_sw;

            [final_path_temp, sw_struct, link] = processPkt_mod(g, link, link_bwd_unit, link_if, host_ip, sw_struct, ...
                preLower, link_struct, flow_entry_temp, flow, final_path_temp, flow_start_datetime, ...
                first_edge_sw, second_edge_sw, dst_name);
            
            final_path = [final_path, final_path_temp];
            final_path_temp = [];
        end
        
        has_hierarchy = false;
    else
        %{src_edge_sw, dst_edge_sw}
        prefix_length = flow_table.prefix(i);
        flow_entry = setFlowEntry(prefix_length, flow_entry, flow_table, i);
        rows = strcmp(link_if.Src_Node, src_name);
        flow_entry.input = link_if{rows, {'Dst_Inf'}};
    
        flow.dst_name = dst_edge_sw;
        [final_path, sw_struct, link] = processPkt_mod(g, link, link_bwd_unit, link_if, host_ip, sw_struct, ...
            preLower, link_struct, flow_entry, flow, final_path, flow_start_datetime, ...
            src_edge_sw, dst_edge_sw, dst_name);
    end
    
    final_path = [final_path, findnode(g, dst_name)];
    final_path(diff(final_path)==0) = [];
    flow_final_path = [flow_final_path; final_path];
    
    rate = flow.rate;
    [link_struct, preLower] = updateLinkStruct(final_path, g, link_struct, flow_start_datetime, flow_end_datetime, flow_end_strtime, preLower, flow_entry, rate);
    
    %{
    if randi(100) >= 95 && prefix_length > 1 && 2 < 1%%%
        prefix_length = prefix_length - 1;
        
        if prefix_length < prefix_threshold
            hierarchy_table.middle_src_sw = repmat({{}}, size(flow_table, 1), 1);
            hierarchy_table.middle_dst_sw = repmat({{}}, size(flow_table, 1), 1);
            hierarchy_table = hierarchical(g, hierarchy_table, prefix_length, sw_vector, host_ip, link_if, flow_table, i+1);
            has_hierarchy = true;
        else
            flow_table.group = repmat({[]}, size(flow_table, 1), 1);
            flow_table = simularityClustering(prefix_length, host_ip, link_if, flow_table, i+1);
        end
        
        updatePrefixLength = false;
    end
    %}
    
    if doHierarchical
        %hierarchy_table.middle_src_sw = repmat({{}}, size(flow_table, 1), 1);
        %hierarchy_table.middle_dst_sw = repmat({{}}, size(flow_table, 1), 1);
        %hierarchy_table.prefix = zeros(size(flow_table, 1), 1);
        
        [flow_table, hie_count] = hierarchical_dtw(g, sw_vector, host_ip, link_if, sw_tooManyFlowEntry, flowEntry_threshold, flow_final_path, hie_count, flow_table, i);
        doHierarchical = false;
    end
end

%stop(schedule)
%delete(schedule)

t2 = datetime('now');
disp(t2 - t1)

%{
function timerFunction(obj, event, flowEntry_threshold)
    datetime('now')
    global sw_struct
    global doHierarchical
    global sw_tooManyFlowEntry

    flowEntryNum = arrayfun(@checkFlowTable, sw_struct);
    rows = (flowEntryNum > flowEntry_threshold);

    if any(rows)
        sw_tooManyFlowEntry = find(rows);
        doHierarchical = true;
    end
end

function entry_number = checkFlowTable(x)
    global current_flow_time
    
    if isempty(x.entry)
        entry_number = 0;
    else
        entry_number = length(find(datetime({x.entry.end_time}, 'Format', 'yyyy-MM-dd HH:mm:ss.SSS') > current_flow_time));
    end
end
%}

function [doHierarchical, sw_tooManyFlowEntry] = checkFlowTable(flowEntry_threshold, sw_struct, doHierarchical, sw_tooManyFlowEntry)
    flowEntryNum = arrayfun(@swFlowEntryNumber, sw_struct);
    rows = (flowEntryNum > flowEntry_threshold);

    if any(rows)
        sw_tooManyFlowEntry = find(rows);
        doHierarchical = true;
    end
end

function entry_number = swFlowEntryNumber(x)
    global current_flow_time
    
    if isempty(x.entry)
        entry_number = 0;
    else
        entry_number = length(find(datetime({x.entry.end_time}, 'Format', 'yyyy-MM-dd HH:mm:ss.SSS') >= current_flow_time));
    end
end