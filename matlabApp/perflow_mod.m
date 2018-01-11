%clearvars
clearvars -except flow_final_path_p link_struct_p final_network_throuput_p flow_final_path_c link_struct_c final_network_throuput_c flow_final_path_h link_struct_h final_network_throuput_h

t1 = datetime('now');

% fat tree
k = 4;
host_x = 200;
host_sd = 5;
[sw_number, srcNode, dstNode, srcInf, dstInf, g, edge_subnet, hostNum] = createFatTreeTopo_mod(k, host_x, host_sd);

%{
% AS_topo
as_edge_sw_num = 10;
host_x = 25;
host_sd = 3;
[sw_number, srcNode, dstNode, srcInf, dstInf, g, asNum, nodeT, edge_subnet, hostNum] = createAsTopo_mod(as_edge_sw_num, host_x, host_sd);
%}

[link_if, host_ip, sw_struct, link, link_struct, flow_table] = setVariables_mod(g, srcNode, dstNode, srcInf, dstInf, sw_number, hostNum, edge_subnet);

link_bwd_unit = 10^3; %10Kbps
flow_final_path = {};
preLower = [];
for i = 1:size(flow_table, 1)
    i    
    [src_name, dst_name, flow_start_datetime, flow_end_datetime, flow_start_strtime, flow_end_strtime, flow, flow_table, flow_entry] = setFlowInfo(link_bwd_unit, host_ip, flow_table, i);

    flow_entry = setFlowEntryForPerflow(flow_entry, flow_table, i);

    rows = strcmp(link_if.Src_Node, src_name);
    flow_entry.input = link_if{rows, {'Dst_Inf'}};
    
    sw = findnode(g, link_if{rows, {'Dst_Node'}}{1});
    
    first_node = findnode(g, src_name);
    final_path = first_node;
    
    flow.dst_name = dst_name;
    
    dst_name_arg = dst_name;
    final_dst_host = dst_name;
    isPerflow = true;
    [final_path, sw_struct, link] = processPkt(g, link, link_bwd_unit, link_if, host_ip, sw_struct, preLower, link_struct, sw, flow_entry, dst_name_arg, final_dst_host, flow, final_path, flow_start_datetime, isPerflow);
    flow_final_path = [flow_final_path; final_path];
    
    rate = flow.rate;
    [link_struct, preLower] = updateLinkStruct(final_path, g, link_struct, flow_start_datetime, flow_end_datetime, flow_end_strtime, preLower, flow_entry, rate);
end

link_struct_temp = link_struct;

% for fat tree
[link_struct, final_network_throuput] = draw_link_througuput(g, link_bwd_unit, link_struct, k, flow_final_path, flow_table);
draw_flow_entry_number(k, sw_struct, sw_number);

% for as topo
%[link_struct, final_network_throuput] = draw_link_througuput(g, link_bwd_unit, link_struct, asNum, flow_final_path, flow_table);
%draw_flow_entry_number(asNum, sw_struct, sw_number);

flow_final_path_p = flow_final_path;
link_struct_p = link_struct;
final_network_throuput_p = final_network_throuput;

t2 = datetime('now');
disp(t2 - t1)