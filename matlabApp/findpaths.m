function paths = findpaths(Adj, nodes, currentPath, start, target)
   paths = {};
   if start == target%{ && length(currentPath) == n%}
      currentPath = [currentPath start];
      paths = [paths; currentPath];
      return; 
   end
   nodes(start) = 0;
   currentPath = [currentPath start];
   childAdj = Adj(start,:) & nodes;
   childList = find(childAdj);
   childCount = numel(childList);
   if childCount == 0
      return;
   end
   for idx = 1:childCount
      currentNode = childList(idx);
      newPaths = findpaths(Adj, nodes, currentPath, currentNode, target);
      paths = [paths; newPaths];
   end
end