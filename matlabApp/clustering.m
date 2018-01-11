clearvars
t1 = datetime('now');

host_x = 15;
host_sd = 3;

% fat tree
%k = 4;
%[sw_number, srcNode, dstNode, srcInf, dstInf, g, edge_subnet, hostNum, IP] = ...
%    createFatTreeTopo_mod(k, host_x, host_sd);

% AS_topo
as_edge_sw_num = 5;
[sw_number, srcNode, dstNode, srcInf, dstInf, g, asNum, nodeT, edge_subnet, hostNum, IP] = ...
    createAsTopo_mod(as_edge_sw_num, host_x, host_sd);

flowNum = 2000;
[link_if, host_ip, sw_struct, link, link_struct, flow_table] = ...
    setVariables_mod(sw_number, srcNode, dstNode, srcInf, dstInf, g, hostNum, IP, flowNum);

sw_vector = distances(g, 'Method', 'unweighted');
sw_vector = sw_vector(1:sw_number, 1:sw_number);

% for as topo
rows = strcmp(nodeT.Type, 'RT_NODE');
sw_vector(rows, rows) = 0;

link_bwd_unit = 10^3; %10Kbps
flow_final_path = {};
preLower = [];

hierarchy_table = table();
hierarchy_table.middle_src_sw = repmat({[]}, size(flow_table, 1), 1);
hierarchy_table.middle_dst_sw = repmat({[]}, size(flow_table, 1), 1);

prefix_length = 16; %bits
prefix_threshold = 16;

has_hierarchy = false;

schedule = timer;
schedule.Period = 3;
schedule.TasksToExecute = inf;
schedule.ExecutionMode = 'fixedRate';
schedule.TimerFcn = 'updatePrefixLength = true;';
schedule.StartDelay = 10;
start(schedule)
updatePrefixLength = false;

flow_table.group = repmat({[]}, size(flow_table, 1), 1);
flow_table = simularityClustering(prefix_length, host_ip, link_if, flow_table, 1);

for i = 1:size(flow_table, 1)
    i
    [src_name, dst_name, flow_start_datetime, flow_end_datetime, flow_start_strtime, flow_end_strtime, ...
        flow, flow_table, flow_entry] = setFlowInfo(link_bwd_unit, host_ip, flow_table, i);
    
    rows = strcmp(link_if.Src_Node, src_name);
    src_edge_sw = link_if{rows, {'Dst_Node'}}{1};
    
    rows = strcmp(link_if.Src_Node, dst_name);
    dst_edge_sw = link_if{rows, {'Dst_Node'}}{1};
    
    final_path = findnode(g, src_name);
    final_path_temp = [];
    
    if has_hierarchy
        middle_src_sw = hierarchy_table.middle_src_sw{i};
        middle_dst_sw = hierarchy_table.middle_dst_sw{i};
        
        sw_list = {src_edge_sw, middle_src_sw, middle_dst_sw, dst_edge_sw};
        prefix_list = [prefix_threshold, prefix_length, prefix_threshold];
       
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
    else
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
    
    if randi(100) >= 95 && prefix_length > 1 %%%
        prefix_length = prefix_length - 1;
        
        if prefix_length < prefix_threshold
            hierarchy_table.middle_src_sw = repmat({[]}, size(flow_table, 1), 1);
            hierarchy_table.middle_dst_sw = repmat({[]}, size(flow_table, 1), 1);
            hierarchy_table = hierarchical(g, hierarchy_table, prefix_length, sw_vector, host_ip, link_if, flow_table, i+1);
            has_hierarchy = true;
        end
        
        flow_table.group = repmat({[]}, size(flow_table, 1), 1);
        flow_table = simularityClustering(prefix_length, host_ip, link_if, flow_table, i+1);
        
        updatePrefixLength = false;
    end
end

stop(schedule)

t2 = datetime('now');
disp(t2 - t1)