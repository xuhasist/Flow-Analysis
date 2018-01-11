function [sw_number, srcNode, dstNode, srcInf, dstInf, g, asNum, nodeT, edge_subnet, hostNum, IP] = createAsTopo_mod(as_edge_sw_num, host_x, host_sd)
    topoInfo = textread('as.brite', '%s', 'delimiter', '\n');
    token = strsplit(topoInfo{1}, ' ');

    swNum = str2double(token{3});
    edgeNum = str2double(token{5});

    nodeCount = zeros(swNum);
    nodeName = {};

    sw_number = swNum;

    for i = 1:swNum
        nodeName{i} = strcat('sw-', int2str(i));
    end

    g = graph(nodeCount, nodeName);
    g_ = graph(zeros(swNum), nodeName(1:swNum));

    token = strsplit(topoInfo{7}, '\t');
    startNodeInd = str2double(token{1});

    srcNode = {};
    dstNode = {};
    srcInf = [];
    dstInf = [];

    if_temp = ones(1,swNum);
    for i = 7+(swNum+3):7+(swNum+3)+(edgeNum-1)
        token = strsplit(topoInfo{i}, '\t');

        node1 = str2double(token{2})+1-startNodeInd;
        node2 = str2double(token{3})+1-startNodeInd;

        %g = addedge(g, node1, node2, str2double(token{6}));
        %g_ = addedge(g_, node1, node2, str2double(token{6}));
        g = addedge(g, node1, node2, 10);
        g_ = addedge(g_, node1, node2, 10);

        srcNode = [srcNode; strcat('sw-', int2str(node1))];
        dstNode = [dstNode; strcat('sw-', int2str(node2))];
        srcInf = [srcInf; if_temp(node1)];
        dstInf = [dstInf; if_temp(node2)];

        srcNode = [srcNode; strcat('sw-', int2str(node2))];
        dstNode = [dstNode; strcat('sw-', int2str(node1))];
        srcInf = [srcInf; if_temp(node2)];
        dstInf = [dstInf; if_temp(node1)];

        if_temp(node2) = if_temp(node2) + 1;
        if_temp(node1) = if_temp(node1) + 1;
    end

    as = [];
    type = {};
    for i = 7:7+(swNum-1)
        token = strsplit(topoInfo{i}, '\t');

        as = [as; str2double(token{6})+1];
        type = [type; token{7}];
    end

    nodeT = table(nodeName(1:swNum)', as, type);
    nodeT.Properties.VariableNames = {'Node', 'AS', 'Type'};

    asNum = length(unique(nodeT.AS));
    host_range = [host_x-host_sd, host_x+host_sd];
    
    green_nodes = [];
    subnet_bin = {};
    subnet_dec = {};
    IP = {};
    edge_sw_order = [];
    for i = 1:asNum
        rows = (nodeT.AS == i) & strcmp(nodeT.Type, 'RT_NODE');
        edge_sw = find(rows);
        edge_sw = edge_sw(randperm(numel(edge_sw), as_edge_sw_num));
        edge_sw_order = [edge_sw_order edge_sw'];
        
        host_at_sw(edge_sw) = randi(host_range, as_edge_sw_num, 1);
        
        green_nodes = [green_nodes edge_sw'];
        
        x = (i-1)*20+1;
        ip_set = (x:1:x+as_edge_sw_num-1);
        sub_ip = dec2bin(ip_set, 8);
        sub_ip = strcat(dec2bin(128, 8), sub_ip);
        subnet_bin = [subnet_bin cellstr(sub_ip)'];
        
        sub_ip = strcat('128.', int2str(ip_set'), '.0.0');
        subnet_dec = [subnet_dec cellstr(sub_ip)'];
        
        for j = 1:length(edge_sw)
            a = randperm(256, host_at_sw(edge_sw(j))) - 1;
            b = randperm(254, host_at_sw(edge_sw(j)));

            IP = [IP, cellstr(strcat('128.', int2str(ip_set(j)), '.', int2str(a'), '.', int2str(b')))'];
        end
    end
    
    hostNum = sum(host_at_sw(host_at_sw>0));
    
    for i = 1:hostNum
        hostName{i} = strcat('h-', int2str(i));
    end
    
    g = addnode(g, hostName);
    
    host_c = 1;
    %edge_sw = find(host_at_sw);
    edge_sw = edge_sw_order;
    for i = 1:length(edge_sw)
        for n = host_c:(host_c + host_at_sw(edge_sw(i))) - 1            
            g = addedge(g, strcat('sw-', int2str(edge_sw(i))), strcat('h-', int2str(n)), 10);  

            srcNode = [srcNode; strcat('sw-', int2str(edge_sw(i)))];
            dstNode = [dstNode; strcat('h-', int2str(n))];
            srcInf = [srcInf; if_temp(edge_sw(i))];
            dstInf = [dstInf; 1];

            srcNode = [srcNode; strcat('h-', int2str(n))];
            dstNode = [dstNode; strcat('sw-', int2str(edge_sw(i)))];
            srcInf = [srcInf; 1];
            dstInf = [dstInf; if_temp(edge_sw(i))];

            if_temp(edge_sw(i)) = if_temp(edge_sw(i)) + 1;
        end

        host_c = host_c + host_at_sw(edge_sw(i));
    end

    x_axis_start = 1;
    %y_axis = [3, 1, 5, 2, 4];
    y_axis = [19, 17, 15, 13, 11, 9, 7, 5, 3, 1, 2, 4, 6, 8, 10, 12, 14, 16, 18, 20];
    y_axis_shift = [20, 30, 10, 40, 1, 30, 10, 20];
    for i = 1:asNum
        rows = (nodeT.AS == i);
        nodes = findnode(g, nodeT{rows, {'Node'}});

        x(nodes) = x_axis_start:x_axis_start+length(nodes)-1;
        y(nodes) = y_axis + y_axis_shift(i);

        if mod(i, 2) ~= 0
            x_axis_start = x_axis_start+length(nodes);
        end
    end

    x(1+swNum:swNum+hostNum) = 1:hostNum;
    y(1+swNum:swNum+hostNum) = 0;

    %topo = plot(g, 'XData', x, 'YData', y);
    topo = plot(g_, 'XData', x(1:swNum), 'YData', y(1:swNum));

    color = {'r', 'g', 'b', 'y', 'm', 'c', 'r', 'k'};
    for i = 1:swNum
        if strcmp(nodeT{i, 'Type'}{1}, 'RT_BORDER')
            highlight(topo, i, 'NodeColor', 'r')
        elseif find(ismember(green_nodes, i) == 1)
            highlight(topo, i, 'NodeColor', 'g')
        else
            highlight(topo, i, 'NodeColor', 'k')
        end
    end

    %green_nodes = sort(green_nodes);
    
    for i = 1:length(green_nodes)
        g.Nodes.Name{green_nodes(i)} = ['ed-', int2str(i)];
        nodeT.Node{green_nodes(i)} = ['ed-', int2str(i)];

        rows = strcmp(srcNode, nodeName{green_nodes(i)});
        srcNode(rows) = {['ed-', int2str(i)]};

        rows = strcmp(dstNode, nodeName{green_nodes(i)});
        dstNode(rows) = {['ed-', int2str(i)]};

        nodeName{green_nodes(i)} = ['ed-', int2str(i)];
    end
    
    edge_subnet = table(g.Nodes.Name(green_nodes), subnet_bin', subnet_dec');
    edge_subnet.Properties.VariableNames = {'Node', 'Subnet_bin', 'Subnet_dec'};
end