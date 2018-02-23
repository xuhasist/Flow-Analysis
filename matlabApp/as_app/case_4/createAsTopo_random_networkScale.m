function [swNum, srcNode, dstNode, srcInf, dstInf, g, asNum, nodeTable, hostNum, IP] = ...
    createAsTopo_random_networkScale(eachAsEdgeSwNum, hostAvg, hostSd, asSize)

    dirName = ['myTopologyInfo_', int2str(asSize), '/'];
    allFile = dir(dirName);

    allFile = {allFile.name};
    rows = contains(allFile, 'myTopo');
    allFile = allFile(rows);
    
    pickTopoFileIndex = randi(length(allFile));
    
    topoInfo = textread([dirName, allFile{pickTopoFileIndex}], '%s', 'delimiter', '\n');
        
    token = strsplit(topoInfo{1}, ' ');
    swNum = str2double(token{3});

    token = strsplit(topoInfo{2}, ' ');
    edgeNum = str2double(token{3});

    nodeCount = zeros(swNum);
    nodeName = {};

    for i = 1:swNum
        nodeName{i} = strcat('sw-', int2str(i));
    end

    g = graph(nodeCount, nodeName);
    %g_ = g;
    
    as = [];
    type = {};
    for i = 4:4+(swNum-1)
        token = strsplit(topoInfo{i}, ' ');

        as = [as; str2double(token{2})+1];
        type = [type; 'RT_NODE'];
    end
    
    nodeTable = table(nodeName(1:swNum)', as, type);
    nodeTable.Properties.VariableNames = {'Node', 'AS', 'Type'};

    srcNode = {};
    dstNode = {};
    srcInf = [];
    dstInf = [];

    if_temp = ones(1,swNum);
    for i = 2+(swNum+3):2+(swNum+3)+(edgeNum-1)
        token = strsplit(topoInfo{i}, ' ');

        node1 = str2double(token{1})+1;
        node2 = str2double(token{2})+1;

        g = addedge(g, node1, node2, 10);
        %g_ = addedge(g_, node1, node2, 10);

        srcNode = [srcNode; strcat('sw-', int2str(node1))];
        dstNode = [dstNode; strcat('sw-', int2str(node2))];
        srcInf = [srcInf; if_temp(node1)];
        dstInf = [dstInf; if_temp(node2)];

        srcNode = [srcNode; strcat('sw-', int2str(node2))];
        dstNode = [dstNode; strcat('sw-', int2str(node1))];
        srcInf = [srcInf; if_temp(node2)];
        dstInf = [dstInf; if_temp(node1)];

        if_temp(node1) = if_temp(node1) + 1;
        if_temp(node2) = if_temp(node2) + 1;
        
        if ~strcmp(token{3}, token{4})
            rows = strcmp(nodeTable.Node, strcat('sw-', int2str(node1))) | strcmp(nodeTable.Node, strcat('sw-', int2str(node2)));
            nodeTable.Type(rows) = {'RT_BORDER'};
        end
    end

    asNum = length(unique(nodeTable.AS));
    hostRange = [hostAvg-hostSd, hostAvg+hostSd];
        
    edgeSwNode = [];
    %subnetBin = {};
    %subnetDec = {};
    IP = {};
    edgeSwOrder = [];
    for i = 1:asNum
        rows = (nodeTable.AS == i) & strcmp(nodeTable.Type, 'RT_NODE');
        edgeSw = find(rows);
        edgeSw = edgeSw(randperm(numel(edgeSw), eachAsEdgeSwNum));
        edgeSwOrder = [edgeSwOrder, edgeSw'];
        
        hostAtSw(edgeSw) = randi(hostRange, eachAsEdgeSwNum, 1);
        
        edgeSwNode = [edgeSwNode, edgeSw'];
                
        ipSet = (randperm(32, eachAsEdgeSwNum)-1) + (32*(i-1));
        
        %subIp = dec2bin(ipSet, 8);
        %subIp = strcat(dec2bin(128, 8), subIp);
        %subnetBin = [subnetBin cellstr(subIp)'];
        
        %subIp = strcat('128.', int2str(ipSet'), '.0.0');
        %subnetDec = [subnetDec cellstr(subIp)'];
        
        for j = 1:length(edgeSw)
            a = randperm(256, hostAtSw(edgeSw(j))) - 1;
            b = randperm(254, hostAtSw(edgeSw(j)));

            IP = [IP, cellstr(strcat('128.', int2str(ipSet(j)), '.', int2str(a'), '.', int2str(b')))'];
        end
    end
    
    hostNum = sum(hostAtSw);
    
    for i = 1:hostNum
        hostName{i} = strcat('h-', int2str(i));
    end
    
    g = addnode(g, hostName);
    
    host_c = 1;
    for i = 1:length(edgeSwOrder)
        for n = host_c:(host_c + hostAtSw(edgeSwOrder(i))) - 1            
            g = addedge(g, strcat('sw-', int2str(edgeSwOrder(i))), strcat('h-', int2str(n)), 10);  

            srcNode = [srcNode; strcat('sw-', int2str(edgeSwOrder(i)))];
            dstNode = [dstNode; strcat('h-', int2str(n))];
            srcInf = [srcInf; if_temp(edgeSwOrder(i))];
            dstInf = [dstInf; 1];

            srcNode = [srcNode; strcat('h-', int2str(n))];
            dstNode = [dstNode; strcat('sw-', int2str(edgeSwOrder(i)))];
            srcInf = [srcInf; 1];
            dstInf = [dstInf; if_temp(edgeSwOrder(i))];

            if_temp(edgeSwOrder(i)) = if_temp(edgeSwOrder(i)) + 1;
        end

        host_c = host_c + hostAtSw(edgeSwOrder(i));
    end

    %{
    x_axis_start = 1;
    y_axis = [19, 17, 15, 13, 11, 9, 7, 5, 3, 1, 2, 4, 6, 8, 10, 12, 14, 16, 18, 20];
    y_axis_shift = [20, 30, 10, 40, 1, 30, 10, 20];
    for i = 1:asNum
        rows = (nodeTable.AS == i);
        nodes = findnode(g, nodeTable{rows, {'Node'}});

        x(nodes) = x_axis_start:x_axis_start+length(nodes)-1;
        y(nodes) = y_axis + y_axis_shift(i);

        if mod(i, 2) ~= 0
            x_axis_start = x_axis_start+length(nodes);
        end
    end

    x(1+swNum:swNum+hostNum) = 1:hostNum;
    y(1+swNum:swNum+hostNum) = 0;

    topo = plot(g_, 'XData', x(1:swNum), 'YData', y(1:swNum));

    color = {'r', 'g', 'b', 'y', 'm', 'c', 'r', 'k'};
    for i = 1:swNum
        if strcmp(nodeTable{i, 'Type'}{1}, 'RT_BORDER')
            highlight(topo, i, 'NodeColor', 'r')
        elseif find(ismember(edgeSwNode, i) == 1)
            highlight(topo, i, 'NodeColor', 'g')
        else
            highlight(topo, i, 'NodeColor', 'k')
        end
    end
    %}
    
    for i = 1:length(edgeSwNode)
        g.Nodes.Name{edgeSwNode(i)} = ['ed-', int2str(i)];
        nodeTable.Node{edgeSwNode(i)} = ['ed-', int2str(i)];

        rows = strcmp(srcNode, nodeName{edgeSwNode(i)});
        srcNode(rows) = {['ed-', int2str(i)]};

        rows = strcmp(dstNode, nodeName{edgeSwNode(i)});
        dstNode(rows) = {['ed-', int2str(i)]};
    end
    
    %edgeSubnet = table(g.Nodes.Name(edgeSwNode), subnetBin', subnetDec');
    %edgeSubnet.Properties.VariableNames = {'Node', 'SubnetBin', 'SubnetDec'};
end