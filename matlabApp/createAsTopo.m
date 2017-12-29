function [sw_number, srcNode, dstNode, srcInf, dstInf, g, asNum, nodeT] = createAsTopo(hostNum)
    topoInfo = textread('as_topo2.brite', '%s', 'delimiter', '\n');
    token = strsplit(topoInfo{1}, ' ');

    swNum = str2double(token{3});
    edgeNum = str2double(token{5});

    nodeCount = zeros(swNum + hostNum);
    nodeName = {};

    sw_number = swNum;

    for i = 1:swNum
        nodeName{i} = strcat('sw-', int2str(i));
    end

    for i = 1+swNum:swNum+hostNum
        nodeName{i} = strcat('h-', int2str(i-(swNum)));
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
    k = sqrt(asNum*2);

    host_at_pod(1:k) = round(hostNum / k);
    host_at_pod(end) = hostNum - round(hostNum / k)*(k-1);


    pod = 1;
    for i = 1:(k/2):asNum
        host_at_sw(i:i+(k/2)-1) = round(host_at_pod(pod) / (k/2));
        host_at_sw(end) = host_at_pod(pod) - round(host_at_pod(pod) / (k/2))*(k/2-1);

        pod = pod + 1;
    end

    host_c = 1;
    m = 1;
    green_nodes = [];
    for i = 1:asNum
        rows = (nodeT.AS == i) & strcmp(nodeT.Type, 'RT_NODE');
        nodes = nodeT{rows, {'Node'}};
        nodes = findnode(g, nodes(1));
        green_nodes = [green_nodes nodes];

        for n = host_c:(host_c+host_at_sw(m))-1            
            g = addedge(g, strcat('sw-', int2str(nodes)), strcat('h-', int2str(n)), 10);  

            srcNode = [srcNode; strcat('sw-', int2str(nodes))];
            dstNode = [dstNode; strcat('h-', int2str(n))];
            srcInf = [srcInf; if_temp(nodes)];
            dstInf = [dstInf; 1];

            srcNode = [srcNode; strcat('h-', int2str(n))];
            dstNode = [dstNode; strcat('sw-', int2str(nodes))];
            srcInf = [srcInf; 1];
            dstInf = [dstInf; if_temp(nodes)];

            if_temp(nodes) = if_temp(nodes) + 1;
        end

        host_c = host_c + host_at_sw(m);
        m = m + 1;
    end

    x_axis_start = 1;
    %y_axis = [3, 1, 5, 2, 4];
    y_axis = [9, 7, 5, 3, 1, 2, 4, 6, 8, 10];
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

    for i = 1:length(green_nodes)
        g.Nodes.Name{green_nodes(i)} = ['ed-', int2str(i)];
        nodeT.Node{green_nodes(i)} = ['ed-', int2str(i)];

        rows = strcmp(srcNode, nodeName{green_nodes(i)});
        srcNode(rows) = {['ed-', int2str(i)]};

        rows = strcmp(dstNode, nodeName{green_nodes(i)});
        dstNode(rows) = {['ed-', int2str(i)]};

        nodeName{green_nodes(i)} = ['ed-', int2str(i)];
    end
end