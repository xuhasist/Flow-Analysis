function [swNum, srcNode, dstNode, srcInf, dstInf, g, hostNum, IP] = ...
    createFatTreeTopo(k, hostAvg, hostSd)

    coreSw = (k/2).^2;
    aggrSw = (k/2) * k;
    edgeSw = (k/2) * k;
    
    nodeCount = zeros(coreSw + aggrSw + edgeSw);
    nodeName = {};

    swNum = coreSw + aggrSw + edgeSw;
    
    for i = 1:coreSw
        nodeName{i} = strcat('co-', int2str(i));
    end

    for i = 1+coreSw:coreSw+aggrSw
        nodeName{i} = strcat('ag-', int2str(i-(coreSw)));
    end

    for i = 1+coreSw+aggrSw:coreSw+aggrSw+edgeSw
        nodeName{i} = strcat('ed-', int2str(i-(coreSw+aggrSw)));
    end

    g = graph(nodeCount, nodeName);
    
    srcNode = {};
    dstNode = {};
    srcInf = [];
    dstInf = [];
    
    % coreSw 1 -> aggreSw 1, 3, 5, 7
    % coreSw 2 -> aggreSw 1, 3, 5, 7
    % coreSw 3 -> aggreSw 2, 4, 6, 8
    % coreSw 4 -> aggreSw 2, 4, 6, 8
    i = 1;
    for j = 1:(k/2):coreSw % control core switch
        if_aggre = 1;

        for n = j:(j+(k/2))-1 % control core switch
            if_core = 1;

            for m = i:(k/2):aggrSw % control aggre switch
                g = addedge(g, strcat('co-', int2str(n)), strcat('ag-', int2str(m)), 10);

                srcNode = [srcNode; strcat('co-', int2str(n))];
                dstNode = [dstNode; strcat('ag-', int2str(m))];
                srcInf = [srcInf; if_core];
                dstInf = [dstInf; if_aggre];

                srcNode = [srcNode; strcat('ag-', int2str(m))];
                dstNode = [dstNode; strcat('co-', int2str(n))];
                srcInf = [srcInf; if_aggre];
                dstInf = [dstInf; if_core];

                if_core = if_core + 1;
            end

            if_aggre = if_aggre + 1;
        end

        i = i + 1;  
    end

    % aggreSw 1 -> edgeSw 1, 2
    % aggreSw 2 -> edgeSw 1, 2
    % aggreSw 3 -> edgeSw 3, 4
    % aggreSw 4 -> edgeSw 3, 4
    for i = 1:(k/2):aggrSw % control aggre switch
        if_edge = 1;

        for j = i:(i+(k/2))-1 % control aggre switch
            if_aggre = (k/2)+1;

            for m = i:(i+(k/2))-1 % control edge switch
                g = addedge(g, strcat('ag-', int2str(j)), strcat('ed-', int2str(m)), 10);

                srcNode = [srcNode; strcat('ag-', int2str(j))];
                dstNode = [dstNode; strcat('ed-', int2str(m))];
                srcInf = [srcInf; if_aggre];
                dstInf = [dstInf; if_edge];

                srcNode = [srcNode; strcat('ed-', int2str(m))];
                dstNode = [dstNode; strcat('ag-', int2str(j))];
                srcInf = [srcInf; if_edge];
                dstInf = [dstInf; if_aggre];

                if_aggre = if_aggre + 1;
            end

            if_edge = if_edge + 1;
        end
    end
    
    hostRange = [hostAvg-hostSd, hostAvg+hostSd];
    hostAtSw(1:edgeSw) = randi(hostRange, edgeSw, 1);
    
    %ipSet = (1:edgeSw);
    ipSet = randperm(32, edgeSw) - 1; % 0~31
    
    %subnetBin = strcat(dec2bin(128, 8), dec2bin(ipSet, 8));
    %subnetBin = cellstr(subnetBin)';
    
    %subnetDec = strcat('128.', int2str(ipSet'), '.0.0');
    %subnetDec = cellstr(subnetDec)';
    
    %edgeSubnet = table(g.Nodes.Name(contains(g.Nodes.Name, 'ed-')), subnetBin', subnetDec');
    %edgeSubnet.Properties.VariableNames = {'Node', 'SubnetBin', 'SubnetDec'};
    
    IP = {};
    for i = 1:edgeSw
        a = randperm(256, hostAtSw(i)) - 1; % 0~255
        b = randperm(254, hostAtSw(i)); % 1~254
        
        IP = [IP, cellstr(strcat('128.', int2str(ipSet(i)), '.', int2str(a'), '.', int2str(b')))'];
    end
        
    hostNum = sum(hostAtSw);
    
    for i = 1:hostNum
        hostName{i} = strcat('h-', int2str(i));
    end
    
    g = addnode(g, hostName);
    
    % edgeSw 1 -> hosts under edgeSw 1
    % edgeSw 2 -> hosts under edgeSw 2
    host_c = 1;
    for j = 1:edgeSw % control edge switch
        if_edge = (k/2)+1;

        for n = host_c:(host_c + hostAtSw(j)) - 1 % control host            
            g = addedge(g, strcat('ed-', int2str(j)), strcat('h-', int2str(n)), 10);  

            srcNode = [srcNode; strcat('ed-', int2str(j))];
            dstNode = [dstNode; strcat('h-', int2str(n))];
            srcInf = [srcInf; if_edge];
            dstInf = [dstInf; 1];

            srcNode = [srcNode; strcat('h-', int2str(n))];
            dstNode = [dstNode; strcat('ed-', int2str(j))];
            srcInf = [srcInf; 1];
            dstInf = [dstInf; if_edge];

            if_edge = if_edge + 1;
        end

        host_c = host_c + hostAtSw(j);
    end
    
    %{
    x(1:coreSw) = 1:floor(hostNum/coreSw):floor(hostNum/coreSw)*coreSw;
    x(1+coreSw:coreSw+aggrSw) = 1:floor(hostNum/aggrSw):floor(hostNum/aggrSw)*aggrSw;
    x(1+coreSw+aggrSw:coreSw+aggrSw+edgeSw) = 1:floor(hostNum/edgeSw):floor(hostNum/edgeSw)*edgeSw;
    x(1+coreSw+aggrSw+edgeSw:coreSw+aggrSw+edgeSw+hostNum) = 1:hostNum;

    y(1:coreSw) = 3;
    y(1+coreSw:coreSw+aggrSw) = 2;
    y(1+coreSw+aggrSw:coreSw+aggrSw+edgeSw) = 1;
    y(1+coreSw+aggrSw+edgeSw:coreSw+aggrSw+edgeSw+hostNum) = 0;

    topo = plot(g, 'XData', x, 'YData', y);
    %}
end