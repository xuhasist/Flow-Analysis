function [path, link] = firstFitFlowScheduling_mod(g, flow, link)
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
        
        [val, loc] = min(table2array(link(pathIndex,'Load')));
        if val < bottleneckLinkLoad || bottleneckLinkLoad == -1
            bottleneckLinkLoad = link.Load(pathIndex(loc));
            bottleneckLinkWeight = link.Weight(pathIndex(loc));
        end
        
        congest = bottleneckLinkLoad / bottleneckLinkWeight;
        if congest < bestPath.congest || bestPath.congest == -1
           bestPath.path = all_shortestPath{j};
           bestPath.congest = congest;
        end
    end

    path = bestPath.path;
end