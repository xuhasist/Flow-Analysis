function [final_path, sw_struct, link] = processPkt(g, link, link_bwd_unit, link_if, host_ip, sw_struct, preLower, link_struct, sw, flow_entry, dst_name_arg, final_dst_host, flow, final_path, flow_start_datetime, isPerflow)
    rows = strcmp(link_if.Src_Node, final_dst_host);
    if sw == findnode(g, link_if{rows, {'Dst_Node'}}{1})
        rows = strcmp(host_ip.Host, final_dst_host);
        flow_entry.dst_ip = host_ip{rows, {'IP'}}{1};
    end

    if sw == findnode(g, dst_name_arg)
        final_path = [final_path sw];
        return
    elseif sw == findnode(g, final_dst_host)
        final_path = [final_path sw];
        return
    end

    if isPerflow
        flow_compare = arrayfun(@(x) isequal(flow_entry.src_ip, x.src_ip) & isequal(flow_entry.dst_ip, x.dst_ip) & isequal(flow_entry.src_port, x.src_port) & isequal(flow_entry.dst_port, x.dst_port) & isequal(flow_entry.protocol, x.protocol) & isequal(flow_entry.input, x.input), sw_struct(sw).entry);
    else
        flow_compare = arrayfun(@(x) isequal(flow_entry.src_ip, x.src_ip) & isequal(flow_entry.dst_ip, x.dst_ip) & isequal(flow_entry.protocol, x.protocol) & isequal(flow_entry.input, x.input), sw_struct(sw).entry);
    end
    
    if ~any(flow_compare)
        flow.src_name = g.Nodes.Name{sw};

        [path, link] = firstFitFlowScheduling(g, link, link_bwd_unit, preLower, link_struct, flow, flow_start_datetime);

        final_path = [final_path path];
        path = g.Nodes.Name(path).';

        rows = strcmp(link_if.Src_Node, g.Nodes.Name{sw}) & strcmp(link_if.Dst_Node, path{2});
        flow_entry.output = link_if{rows, {'Src_Inf'}};

        if isempty(sw_struct(sw).entry)
            sw_struct(sw).entry = flow_entry;
        else
            sw_struct(sw).entry(end+1) = flow_entry;
        end

        [sw_struct] = installFlowRule(g, path, link_if, host_ip, sw_struct, flow_entry, final_dst_host, isPerflow);
    else
        same_flow_loc = find(flow_compare == 1);
        same_flow_loc = same_flow_loc(end);

        old_flow_end_time = datetime(sw_struct(sw).entry(same_flow_loc).end_time, 'Format', 'yyyy-MM-dd HH:mm:ss.SSS');
        new_flow_start_time = datetime(flow_entry.start_time, 'Format', 'yyyy-MM-dd HH:mm:ss.SSS');

        if new_flow_start_time - old_flow_end_time > seconds(60)
            flow.src_name = g.Nodes.Name{sw};

            [path, link] = firstFitFlowScheduling(g, link, link_bwd_unit, preLower, link_struct, flow, flow_start_datetime);

            final_path = [final_path path];
            path = g.Nodes.Name(path).';

            rows = strcmp(link_if.Src_Node, g.Nodes.Name{sw}) & strcmp(link_if.Dst_Node, path{2});
            flow_entry.output = link_if{rows, {'Src_Inf'}};

            sw_struct(sw).entry(end+1) = flow_entry;

            [sw_struct] = installFlowRule(g, path, link_if, host_ip, sw_struct, flow_entry, final_dst_host, isPerflow);
        else
            final_path = [final_path sw];

            new_flow_end_time = datetime(flow_entry.end_time, 'Format', 'yyyy-MM-dd HH:mm:ss.SSS');
            sw_struct(sw).entry(same_flow_loc).end_time = datestr(max(old_flow_end_time, new_flow_end_time), 'yyyy-mm-dd HH:MM:ss.FFF');

            rows = strcmp(link_if.Src_Node, g.Nodes.Name{sw}) & (link_if.Src_Inf == sw_struct(sw).entry(same_flow_loc).output);
            sw = findnode(g, link_if{rows, {'Dst_Node'}}{1});
            flow_entry.input = link_if{rows, {'Dst_Inf'}};

            [final_path, sw_struct, link] = processPkt(g, link, link_bwd_unit, link_if, host_ip, sw_struct, preLower, link_struct, sw, flow_entry, dst_name_arg, final_dst_host, flow, final_path, flow_start_datetime, isPerflow);
        end
    end
end

function [sw_struct] = installFlowRule(g, path, link_if, host_ip, sw_struct, flow_entry, final_dst_host, isPerflow)
    for j = 2:length(path)-1
        if j == length(path)-1
            rows = strcmp(link_if.Src_Node, final_dst_host);
            if findnode(g, path{j}) == findnode(g, link_if{rows, {'Dst_Node'}}{1})
                rows = strcmp(host_ip.Host, final_dst_host);
                flow_entry.dst_ip = host_ip{rows, {'IP'}}{1};
            end
        end
    
        rows = strcmp(link_if.Src_Node, path{j-1}) & strcmp(link_if.Dst_Node, path{j});
        flow_entry.input = link_if{rows, {'Dst_Inf'}};

        rows = strcmp(link_if.Src_Node, path{j}) & strcmp(link_if.Dst_Node, path{j+1});
        flow_entry.output = link_if{rows, {'Src_Inf'}};

        sw = findnode(g, path{j});

        if isPerflow
            flow_compare = arrayfun(@(x) isequal(flow_entry.src_ip, x.src_ip) & isequal(flow_entry.dst_ip, x.dst_ip) & isequal(flow_entry.src_port, x.src_port) & isequal(flow_entry.dst_port, x.dst_port) & isequal(flow_entry.protocol, x.protocol) & isequal(flow_entry.input, x.input) & isequal(flow_entry.output, x.output), sw_struct(sw).entry);
        else
            flow_compare = arrayfun(@(x) isequal(flow_entry.src_ip, x.src_ip) & isequal(flow_entry.dst_ip, x.dst_ip) & isequal(flow_entry.protocol, x.protocol) & isequal(flow_entry.input, x.input) & isequal(flow_entry.output, x.output), sw_struct(sw).entry);
        end
        
        if ~any(flow_compare)
            if isempty(sw_struct(sw).entry)
                sw_struct(sw).entry = flow_entry;
            else
                sw_struct(sw).entry(end+1) = flow_entry;
            end
        else
            same_flow_loc = find(flow_compare == 1);
            same_flow_loc = same_flow_loc(end);
            
            old_flow_end_time = datetime(sw_struct(sw).entry(same_flow_loc).end_time, 'Format', 'yyyy-MM-dd HH:mm:ss.SSS');
            new_flow_start_time = datetime(flow_entry.start_time, 'Format', 'yyyy-MM-dd HH:mm:ss.SSS');
            
            if new_flow_start_time - old_flow_end_time > seconds(60)
                sw_struct(sw).entry(end+1) = flow_entry;
            else
                new_flow_end_time = datetime(flow_entry.end_time, 'Format', 'yyyy-MM-dd HH:mm:ss.SSS');
                sw_struct(sw).entry(same_flow_loc).end_time = datestr(max(old_flow_end_time, new_flow_end_time), 'yyyy-mm-dd HH:MM:ss.FFF');
            end
        end
    end
end

function [path, link] = firstFitFlowScheduling(g, link, link_bwd_unit, preLower, link_struct, flow, flow_start_datetime)
    src_node = findnode(g, flow.src_name);
    dst_node = findnode(g, flow.dst_name);
    
    all_shortestPath = dijkstra(g, src_node, dst_node);
    
    bestPath.congest = -1;
    bestPath.path = '';
    for j = 1:length(all_shortestPath)
        bottleneckLinkLoad = -1;
        bottleneckLinkWeight = 0;
        pathIndex = [];
        for k = 1:length(all_shortestPath{j})-1
            pathIndex = [pathIndex findedge(g, all_shortestPath{j}(k), all_shortestPath{j}(k+1))];
        end
        
        for i = 1:length(pathIndex)
            link = update_link_load(link, preLower, link_struct, flow_start_datetime, pathIndex(i));
        end
        
        [val, loc] = min(link{pathIndex,'Load'});
        if val < bottleneckLinkLoad || bottleneckLinkLoad == -1
            bottleneckLinkLoad = link.Load(pathIndex(loc));
            bottleneckLinkLoad = bottleneckLinkLoad * 8;
            
            bottleneckLinkWeight = link.Weight(pathIndex(loc));
            bottleneckLinkWeight = bottleneckLinkWeight * link_bwd_unit;
        end
        
        congest = bottleneckLinkLoad / bottleneckLinkWeight;
        if congest < bestPath.congest || bestPath.congest == -1
           bestPath.path = all_shortestPath{j};
           bestPath.congest = congest;
        end
    end

    path = bestPath.path;
end

function paths = dijkstra(g, start, target)
    g_adj = adjacency(g);

    nodes = ones(1, size(g_adj,1));
    dist(1:length(g_adj)) = 32767;
    visited(1:length(g_adj)) = false;
    dist(start) = 0;
    tempDist = dist;

    while nodes(target) == 1
        u = find(tempDist == min(dist(logical(nodes(:)))), 1);
        nodes(u) = 0;
        tempDist(u) = -1;
        visited(u) = true;
        childAdj = g_adj(u,:) & ~visited;
        childList = find(childAdj);
        for i = 1:length(childList)
           v = childList(i);
           if dist(v) > dist(u) + g.Edges.Weight(findedge(g, u, v)) 
               dist(v) = dist(u) + g.Edges.Weight(findedge(g, u, v));
               tempDist(v) = dist(v);
               previous{v} = u;
           elseif dist(v) == dist(u) + g.Edges.Weight(findedge(g, u, v))
               previous{v} = [previous{v} u];
           end
        end
    end
    
    currentPath = [];
    paths = findpaths(previous, start, target, currentPath);
end

function paths = findpaths(previous, start, target, currentPath)
    paths = {};
    if start == target
      currentPath = [target currentPath];
      paths = [paths; currentPath];
      return; 
    end
    currentPath = [target currentPath];
    for i = 1:length(previous{target})
        preNode = previous{target}(i);
        newPath = findpaths(previous, start, preNode, currentPath);
        paths = [paths; newPath];
    end    
end

function link = update_link_load(link, preLower, link_struct, flow_start_datetime, edge)    
    if isempty(link_struct(edge).entry)
        return
    end

    rows = (flow_start_datetime >= datetime({link_struct(edge).entry(preLower(edge):end).start_time}', 'Format', 'yyyy-MM-dd HH:mm:ss.SSS')) & (flow_start_datetime < datetime({link_struct(edge).entry(preLower(edge):end).end_time}', 'Format', 'yyyy-MM-dd HH:mm:ss.SSS'));

    if find(rows == 1)
        link(edge, {'Load'}) = {link_struct(edge).entry(find(rows == 1) + preLower(edge) - 1).load};
    end
end