function paths = dijkstra(G, start, target)
    adj = adjacency(G);
    nodes = ones(1, size(adj,1));
    dist(1:length(adj)) = 1000;
    visited(1:length(adj)) = false;
    dist(start) = 0;
    tempDist = dist;
    while sum(nodes == 1) > 0
        u = find(tempDist == min(dist(logical(nodes(:)))), 1);
        nodes(u) = 0;
        tempDist(u) = -1;
        visited(u) = true;
        childAdj = adj(u,:) & ~visited;
        childList = find(childAdj);
        for i = 1:length(childList)
           v = childList(i);
           if dist(v) > dist(u) + G.Edges.Weight(findedge(G, u, v)) 
               dist(v) = dist(u) + G.Edges.Weight(findedge(G, u, v));
               tempDist(v) = dist(v);
               previous{v} = u;
           elseif dist(v) == dist(u) + G.Edges.Weight(findedge(G, u, v))
               previous{v} = [previous{v} u];
           end
        end
    end
    paths = findpaths(previous, start, target, []);
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