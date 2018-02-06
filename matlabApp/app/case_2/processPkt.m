function [finalPath, swFlowEntryStruct, linkTable] = ...
                processPkt(g, linkTable, linkBwdUnit, swInfTable, hostIpTable, ...
                swFlowEntryStruct, linkPreLower, linkThputStruct, flowEntry, finalPath, ...
                flowStartDatetime, srcEdgeSw, dstEdgeSw, round, dstNodeName, flowSrcIp, flowDstIp)

    %finish = false;
    %if strcmp(srcEdgeSw, dstNodeName)
        %finish = true;
        %return
    %end

    if strcmp(srcEdgeSw, dstEdgeSw)
        rows = strcmp(swInfTable.SrcNode, dstNodeName);
        
        if strcmp(dstEdgeSw, swInfTable{rows, {'DstNode'}}{1}) && round == 3
            rows = strcmp(hostIpTable.Host, dstNodeName);
            
            dip = strsplit(hostIpTable{rows, {'IP'}}{1}, '.');
            dip = cellfun(@(x) str2num(x), dip);
            dip = dec2bin(dip, 8);
            dip = dip';

            flowEntry.dstIp = dip(1:32);
            
            swFlowEntryStruct = installLastEdgeSwFlowRule(g, swInfTable, swFlowEntryStruct, flowEntry, dstEdgeSw, dstNodeName);
            finalPath = [finalPath, findnode(g, dstEdgeSw)];
            
            return
        else
            return
        end
    end

    sw = findnode(g, srcEdgeSw);
    
    % prefix more long, flow entry priority more high
    flow_compare = arrayfun(@(x) startsWith(flowSrcIp, x.srcIp) & startsWith(flowDstIp, x.dstIp) & isequal(flowEntry.srcPort, x.srcPort) & isequal(flowEntry.dstPort, x.dstPort) & isequal(flowEntry.protocol, x.protocol) & isequal(flowEntry.input, x.input), swFlowEntryStruct(sw).entry);
    
    if ~any(flow_compare)
        [path, linkTable] = firstFitFlowScheduling(g, linkTable, linkBwdUnit, linkPreLower, linkThputStruct, srcEdgeSw, dstEdgeSw, flowStartDatetime);

        finalPath = [finalPath, path(1:end)];
        path = g.Nodes.Name(path).';

        rows = strcmp(swInfTable.SrcNode, srcEdgeSw) & strcmp(swInfTable.DstNode, path{2});
        flowEntry.output = swInfTable{rows, {'SrcInf'}};

        if isempty(swFlowEntryStruct(sw).entry)
            swFlowEntryStruct(sw).entry = flowEntry;
        else
            swFlowEntryStruct(sw).entry(end+1) = flowEntry;
        end

        swFlowEntryStruct = installFlowRule(g, path, swInfTable, hostIpTable, swFlowEntryStruct, flowEntry, round, dstNodeName);
    else
        sameFlowLoc = find(flow_compare);
        rows = datetime({swFlowEntryStruct(sw).entry(sameFlowLoc).endTime}, 'Format', 'yyyy-MM-dd HH:mm:ss.SSS') >= datetime(flowEntry.startTime, 'Format', 'yyyy-MM-dd HH:mm:ss.SSS');
        sameFlowLoc = sameFlowLoc(rows);
        
        if ~isempty(sameFlowLoc)
            if length(sameFlowLoc) >= 2
                rows = arrayfun(@(x) length(x.srcIp), swFlowEntryStruct(sw).entry(sameFlowLoc));
                max_loc = find(rows == max(rows));
                sameFlowLoc = sameFlowLoc(max_loc(end));
            end

            oldFlowEndTime = datetime(swFlowEntryStruct(sw).entry(sameFlowLoc).endTime, 'Format', 'yyyy-MM-dd HH:mm:ss.SSS');
            newFlowStartTime = datetime(flowEntry.startTime, 'Format', 'yyyy-MM-dd HH:mm:ss.SSS');
        end
        
        if isempty(sameFlowLoc) || (newFlowStartTime - oldFlowEndTime > seconds(60))
            [path, linkTable] = firstFitFlowScheduling(g, linkTable, linkBwdUnit, linkPreLower, linkThputStruct, srcEdgeSw, dstEdgeSw, flowStartDatetime);

            finalPath = [finalPath, path(1:end)];
            path = g.Nodes.Name(path).';

            rows = strcmp(swInfTable.SrcNode, srcEdgeSw) & strcmp(swInfTable.DstNode, path{2});
            flowEntry.output = swInfTable{rows, {'SrcInf'}};

            swFlowEntryStruct(sw).entry(end+1) = flowEntry;

            swFlowEntryStruct = installFlowRule(g, path, swInfTable, hostIpTable, swFlowEntryStruct, flowEntry, round, dstNodeName);
        else
            finalPath = [finalPath, sw];

            newFlowEndTime = datetime(flowEntry.endTime, 'Format', 'yyyy-MM-dd HH:mm:ss.SSS');
            swFlowEntryStruct(sw).entry(sameFlowLoc).endTime = datestr(max(oldFlowEndTime, newFlowEndTime), 'yyyy-mm-dd HH:MM:ss.FFF');

            rows = strcmp(swInfTable.SrcNode, srcEdgeSw) & (swInfTable.SrcInf == swFlowEntryStruct(sw).entry(sameFlowLoc).output);
            srcEdgeSw = swInfTable{rows, {'DstNode'}}{1};
            flowEntry.input = swInfTable{rows, {'DstInf'}};

            [finalPath, swFlowEntryStruct, linkTable] = ...
                processPkt(g, linkTable, linkBwdUnit, swInfTable, hostIpTable, ...
                swFlowEntryStruct, linkPreLower, linkThputStruct, flowEntry, finalPath, ...
                flowStartDatetime, srcEdgeSw, dstEdgeSw, round, dstNodeName, flowSrcIp, flowDstIp);
        end
    end
end

function swFlowEntryStruct = installFlowRule(g, path, swInfTable, hostIpTable, swFlowEntryStruct, flowEntry, round, dstNodeName)
    for j = 2:length(path)-1    
        rows = strcmp(swInfTable.SrcNode, path{j-1}) & strcmp(swInfTable.DstNode, path{j});
        flowEntry.input = swInfTable{rows, {'DstInf'}};

        rows = strcmp(swInfTable.SrcNode, path{j}) & strcmp(swInfTable.DstNode, path{j+1});
        flowEntry.output = swInfTable{rows, {'SrcInf'}};

        sw = findnode(g, path{j});

        flow_compare = arrayfun(@(x) isequal(flowEntry.srcIp, x.srcIp) & isequal(flowEntry.dstIp, x.dstIp) & isequal(flowEntry.srcPort, x.srcPort) & isequal(flowEntry.dstPort, x.dstPort) & isequal(flowEntry.protocol, x.protocol) & isequal(flowEntry.input, x.input) & isequal(flowEntry.output, x.output), swFlowEntryStruct(sw).entry);
        
        if ~any(flow_compare)
            if isempty(swFlowEntryStruct(sw).entry)
                swFlowEntryStruct(sw).entry = flowEntry;
            else
                swFlowEntryStruct(sw).entry(end+1) = flowEntry;
            end
        else
            sameFlowLoc = find(flow_compare);
            rows = datetime({swFlowEntryStruct(sw).entry(sameFlowLoc).endTime}, 'Format', 'yyyy-MM-dd HH:mm:ss.SSS') >= datetime(flowEntry.startTime, 'Format', 'yyyy-MM-dd HH:mm:ss.SSS');
            sameFlowLoc = sameFlowLoc(rows);
            
            if ~isempty(sameFlowLoc)
                sameFlowLoc = sameFlowLoc(end);

                oldFlowEndTime = datetime(swFlowEntryStruct(sw).entry(sameFlowLoc).endTime, 'Format', 'yyyy-MM-dd HH:mm:ss.SSS');
                newFlowStartTime = datetime(flowEntry.startTime, 'Format', 'yyyy-MM-dd HH:mm:ss.SSS');
            end

            if isempty(sameFlowLoc) || (newFlowStartTime - oldFlowEndTime > seconds(60))
                swFlowEntryStruct(sw).entry(end+1) = flowEntry;
            else
                newFlowEndTime = datetime(flowEntry.endTime, 'Format', 'yyyy-MM-dd HH:mm:ss.SSS');
                swFlowEntryStruct(sw).entry(sameFlowLoc).endTime = datestr(max(oldFlowEndTime, newFlowEndTime), 'yyyy-mm-dd HH:MM:ss.FFF');
            end
        end
    end
    
    rows = strcmp(swInfTable.SrcNode, dstNodeName);
    if strcmp(path{end}, swInfTable{rows, {'DstNode'}}{1}) && round == 3
        rows = strcmp(hostIpTable.Host, dstNodeName);
        
        dip = strsplit(hostIpTable{rows, {'IP'}}{1}, '.');
        dip = cellfun(@(x) str2num(x), dip);
        dip = dec2bin(dip, 8);
        dip = dip';

        flowEntry.dstIp = dip(1:32);

        dstEdgeSw = path{end};
        swFlowEntryStruct = installLastEdgeSwFlowRule(g, swInfTable, swFlowEntryStruct, flowEntry, dstEdgeSw, dstNodeName);
    end 
end

function swFlowEntryStruct = installLastEdgeSwFlowRule(g, swInfTable, swFlowEntryStruct, flowEntry, dstEdgeSw, dstNodeName)
    sw = findnode(g, dstEdgeSw);
    flow_compare = arrayfun(@(x) isequal(flowEntry.srcIp, x.srcIp) & isequal(flowEntry.dstIp, x.dstIp) & isequal(flowEntry.srcPort, x.srcPort) & isequal(flowEntry.dstPort, x.dstPort) & isequal(flowEntry.protocol, x.protocol) & isequal(flowEntry.input, x.input), swFlowEntryStruct(sw).entry);
    
    if ~any(flow_compare)
        rows = strcmp(swInfTable.SrcNode, dstEdgeSw) & strcmp(swInfTable.DstNode, dstNodeName);
        flowEntry.output = swInfTable{rows, {'SrcInf'}};

        if isempty(swFlowEntryStruct(sw).entry)
            swFlowEntryStruct(sw).entry = flowEntry;
        else
            swFlowEntryStruct(sw).entry(end+1) = flowEntry;
        end
    else
        sameFlowLoc = find(flow_compare);
        rows = datetime({swFlowEntryStruct(sw).entry(sameFlowLoc).endTime}, 'Format', 'yyyy-MM-dd HH:mm:ss.SSS') >= datetime(flowEntry.startTime, 'Format', 'yyyy-MM-dd HH:mm:ss.SSS');
        sameFlowLoc = sameFlowLoc(rows);

        if ~isempty(sameFlowLoc)
            %sameFlowLoc = sameFlowLoc(end);
            
            oldFlowEndTime = datetime(swFlowEntryStruct(sw).entry(sameFlowLoc).endTime, 'Format', 'yyyy-MM-dd HH:mm:ss.SSS');
            newFlowStartTime = datetime(flowEntry.startTime, 'Format', 'yyyy-MM-dd HH:mm:ss.SSS');
        end

        if isempty(sameFlowLoc) || (newFlowStartTime - oldFlowEndTime > seconds(60))
            rows = strcmp(swInfTable.SrcNode, dstEdgeSw) & strcmp(swInfTable.DstNode, dstNodeName);
            flowEntry.output = swInfTable{rows, {'SrcInf'}};

            swFlowEntryStruct(sw).entry(end+1) = flowEntry;
        else
            newFlowEndTime = datetime(flowEntry.endTime, 'Format', 'yyyy-MM-dd HH:mm:ss.SSS');
            swFlowEntryStruct(sw).entry(sameFlowLoc).endTime = datestr(max(oldFlowEndTime, newFlowEndTime), 'yyyy-mm-dd HH:MM:ss.FFF');
        end
    end
end

function [path, linkTable] = firstFitFlowScheduling(g, linkTable, linkBwdUnit, linkPreLower, linkThputStruct, srcEdgeSw, dstEdgeSw, flowStartDatetime)
    srcNode = findnode(g, srcEdgeSw);
    dstNode = findnode(g, dstEdgeSw);
    
    allShortestPath = dijkstra(g, srcNode, dstNode);
        
    bestPath.congest = -1;
    bestPath.path = '';
    for j = 1:length(allShortestPath)
        bottleneckLinkLoad = -1;
        bottleneckLinkWeight = 0;
        pathIndex = [];
        for k = 1:length(allShortestPath{j})-1
            pathIndex = [pathIndex, findedge(g, allShortestPath{j}(k), allShortestPath{j}(k+1))];
        end
        
        linkTable.Load = zeros(size(linkTable, 1), 1);
        linkTable = updateLinkLoad(linkTable, linkPreLower, linkThputStruct, flowStartDatetime, pathIndex);
        
        [val, loc] = min(linkTable{pathIndex,'Load'});
        if val < bottleneckLinkLoad || bottleneckLinkLoad == -1
            bottleneckLinkLoad = val; %Bytes
            bottleneckLinkLoad = bottleneckLinkLoad * 8; %bits
            
            bottleneckLinkWeight = linkTable.Weight(pathIndex(loc));
            bottleneckLinkWeight = bottleneckLinkWeight * linkBwdUnit; %10Kbps
        end
        
        congest = bottleneckLinkLoad / bottleneckLinkWeight;
        if congest < bestPath.congest || bestPath.congest == -1
           bestPath.path = allShortestPath{j};
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

% find current link load
function linkTable = updateLinkLoad(linkTable, linkPreLower, linkThputStruct, flowStartDatetime, pathIndex)  
    for i = 1:length(pathIndex)
        % No flow through this link yet
        if isempty(linkThputStruct(pathIndex(i)).entry)
            continue
        end

        rows = (flowStartDatetime >= datetime({linkThputStruct(pathIndex(i)).entry(linkPreLower(pathIndex(i)):end).startTime}', 'Format', 'yyyy-MM-dd HH:mm:ss.SSS')) ...
            & (flowStartDatetime < datetime({linkThputStruct(pathIndex(i)).entry(linkPreLower(pathIndex(i)):end).endTime}', 'Format', 'yyyy-MM-dd HH:mm:ss.SSS'));

        if any(rows)
            linkTable(pathIndex(i), {'Load'}) = {linkThputStruct(pathIndex(i)).entry(find(rows) + linkPreLower(pathIndex(i)) - 1).load};
        end
    end
end