%clearvars
clearvars -except flow_final_path_p link_struct_p final_network_throuput_p flow_final_path_c link_struct_c final_network_throuput_c flow_final_path_h link_struct_h final_network_throuput_h

t1 = datetime('now');

%{
% fat tree
k = 4;
host_x = 10;
host_sd = 3;
[sw_number, srcNode, dstNode, srcInf, dstInf, g, edge_subnet, hostNum] = createFatTreeTopo_mod(k, host_x, host_sd);

%}

% AS_topo
as_edge_sw_num = 5;
host_x = 15;
host_sd = 3;
[sw_number, srcNode, dstNode, srcInf, dstInf, g, asNum, nodeT, edge_subnet, hostNum] = createAsTopo_mod(as_edge_sw_num, host_x, host_sd);

[link_if, host_ip, sw_struct, link, link_struct, flow_table] = setVariables_mod(g, srcNode, dstNode, srcInf, dstInf, sw_number, hostNum, edge_subnet);

sw_vector = distances(g, 'Method', 'unweighted');
sw_vector = sw_vector(1:sw_number, 1:sw_number);

% for as topo
rows = strcmp(nodeT.Type, 'RT_NODE');
sw_vector(rows, rows) = 0;

% user clustering
hierarchy_cluster = hierarchy_user_clustering(g, flow_table, edge_subnet, sw_vector, host_ip, link_if);

%{
for i = 1:max(unique(hierarchy_cluster.hie_index))
    rows = (hierarchy_cluster.hie_index == i);
    
    srcSw = unique(hierarchy_cluster{rows, {'srcEdgeSw'}});
    dstSw = unique(hierarchy_cluster{rows, {'dstEdgeSw'}});

    for j = 1:length(srcSw)
        srcSw(j) = findnode(g, ['ed-', int2str(srcSw(j))]);
    end
    
    for j = 1:length(dstSw)
        dstSw(j) = findnode(g, ['ed-', int2str(dstSw(j))]);
    end
    
    middleSw_1 = find_middle_sw(srcSw, sw_vector);
    middleSw_2 = find_middle_sw(dstSw, sw_vector);
    
    hierarchy_cluster{rows,{'middleSw_1'}} = middleSw_1;
    hierarchy_cluster{rows,{'middleSw_2'}} = middleSw_2;
end
%}

link_bwd_unit = 10^3; %10Kbps
flow_final_path = {};
preLower = [];

for i = 1:size(flow_table, 1)
    i    
    [src_name, dst_name, flow_start_datetime, flow_end_datetime, flow_start_strtime, flow_end_strtime, flow, flow_table, flow_entry] = setFlowInfo(link_bwd_unit, host_ip, flow_table, i);
    
    if hierarchy_cluster{i, {'hie_index'}} == -1
        has_hie = false;
        loop_count = 1;
        group_arg = flow_table{i, 'group'};
    else
        has_hie = true;
        middleSw_1 = hierarchy_cluster{i, {'middleSw_1'}};
        middleSw_2 = hierarchy_cluster{i, {'middleSw_2'}};
        group2 = hierarchy_cluster{i, {'group2'}};
        
        if middleSw_1 == -1
            middleSw_1 = middleSw_2;
            middleSw_2 = findnode(g, dst_name);
            loop_count = 2;
            group_arg = [flow_table{i, 'group'}, flow_table{i, 'group'}];
        elseif middleSw_1 == middleSw_2 || middleSw_2 == -1
            middleSw_2 = findnode(g, dst_name);
            loop_count = 2;
            group_arg = [flow_table{i, 'group'}, flow_table{i, 'group'}];
        else
            loop_count = 3;
            group_arg = [flow_table{i, 'group'}, hierarchy_cluster{i, 'group2'}, flow_table{i, 'group'}];
        end
    end
    
    flow_final_path_tmp = [];
    for m = 1:loop_count
        group = group_arg(m);
        flow_entry = setFlowEntryForCluster(flow_entry, flow_table, i, group);

        if m == 1
            rows = strcmp(link_if.Src_Node, src_name);
            flow_entry.input = link_if{rows, {'Dst_Inf'}};

            sw = findnode(g, link_if{rows, {'Dst_Node'}}{1});

            first_node = findnode(g, src_name);
            final_path = first_node;
            
            if ~has_hie
                dst_name_arg = dst_name;
            else
                dst_name_arg = g.Nodes.Name{middleSw_1};
            end
            
            flow.dst_name = dst_name_arg;
        elseif m == 2
            rows = strcmp(link_if.Src_Node, g.Nodes.Name{final_path(end-1)}) & strcmp(link_if.Dst_Node, g.Nodes.Name{final_path(end)});
            flow_entry.input = link_if{rows, {'Dst_Inf'}};
            
            sw = final_path(end);
            final_path = [];
            
            dst_name_arg = g.Nodes.Name{middleSw_2};
            flow.dst_name = dst_name_arg;
        elseif m == 3
            rows = strcmp(link_if.Src_Node, g.Nodes.Name{final_path(end-1)}) & strcmp(link_if.Dst_Node, g.Nodes.Name{final_path(end)});
            flow_entry.input = link_if{rows, {'Dst_Inf'}};
            
            sw = final_path(end);
            final_path = [];
            
            dst_name_arg = dst_name;
            flow.dst_name = dst_name_arg;
        end

        isPerflow = false;
        final_dst_host = dst_name;
        [final_path, sw_struct, link] = processPkt(g, link, link_bwd_unit, link_if, host_ip, sw_struct, preLower, link_struct, sw, flow_entry, dst_name_arg, final_dst_host, flow, final_path, flow_start_datetime, isPerflow);
        flow_final_path_tmp = [flow_final_path_tmp final_path];

        rate = flow.rate;
        [link_struct, preLower] = updateLinkStruct(final_path, g, link_struct, flow_start_datetime, flow_end_datetime, flow_end_strtime, preLower, flow_entry, rate);
    end
    
    flow_final_path = [flow_final_path; flow_final_path_tmp];
end

link_struct_temp = link_struct;

[link_struct, final_network_throuput] = draw_link_througuput(g, link_bwd_unit, link_struct, k, flow_final_path, flow_table);
draw_flow_entry_number(k, sw_struct, sw_number);

% for as topo
%[link_struct, final_network_throuput] = draw_link_througuput(g, link_bwd_unit, link_struct, asNum, flow_final_path, flow_table);
%draw_flow_entry_number(asNum, sw_struct, sw_number);

flow_final_path_h = flow_final_path;
link_struct_h = link_struct;
final_network_throuput_h = final_network_throuput;

t2 = datetime('now');
disp(t2 - t1)

function middleSw = find_middle_sw(sw, sw_vector)    
    middleSw = -1;
    
    j = 1;
    while true
        if length(sw) == 1
            break;
        end
        
        for m = 1:length(sw)
            tmp_list{m} = find(ismember(sw_vector(sw(m), :), (1:j)));
        end
         
        for m = 1:length(tmp_list)-1
            tmp_list{m+1} = intersect(tmp_list{m}, tmp_list{m+1});
        end
        
        if ~isempty(tmp_list{m+1})
            %middleSw = tmp_list{end}(randi(numel(tmp_list{end}),1,1));
            middleSw = tmp_list{end}(1);
            break
        elseif j == max(max(sw_vector(sw, :)))
            break
        else
            j = j + 1;
        end     
    end
end