clearvars

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

flowNum = 10000;
[link_if, host_ip, sw_struct, link, link_struct, flow_table, sequence] = ...
    setVariables_mod(sw_number, srcNode, dstNode, srcInf, dstInf, g, hostNum, IP, flowNum);

link_bwd_unit = 10^3; %10Kbps
flow_final_path = {};
preLower = [];

prefix_length = 16;

flow_table.group = repmat(-1, size(flow_table, 1), 1);

%flow_table = simularityClustering(prefix_length, host_ip, link_if, flow_table, 1);
%flow_table = simularityClustering_dtw(g, host_ip, link_if, flow_table, sequence);
flow_table = simularityClustering_fixPrefix(g, prefix_length, host_ip, link_if, flow_table, sequence);

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
    
    %{src_edge_sw, dst_edge_sw}
    prefix_length = flow_table.prefix(i);
    flow_entry = setFlowEntry(prefix_length, flow_entry, flow_table, i);
    rows = strcmp(link_if.Src_Node, src_name);
    flow_entry.input = link_if{rows, {'Dst_Inf'}};

    flow.dst_name = dst_edge_sw;
    [final_path, sw_struct, link] = processPkt_mod(g, link, link_bwd_unit, link_if, host_ip, sw_struct, ...
        preLower, link_struct, flow_entry, flow, final_path, flow_start_datetime, ...
        src_edge_sw, dst_edge_sw, dst_name);
    
    final_path = [final_path, findnode(g, dst_name)];
    final_path(diff(final_path)==0) = [];
    flow_final_path = [flow_final_path; final_path];
    
    rate = flow.rate;
    [link_struct, preLower] = updateLinkStruct(final_path, g, link_struct, flow_start_datetime, flow_end_datetime, flow_end_strtime, preLower, flow_entry, rate);
end

t2 = datetime('now');
disp(t2 - t1)