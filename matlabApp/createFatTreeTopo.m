function [sw_number, srcNode, dstNode, srcInf, dstInf, g] = createFatTreeTopo(k, hostNum)
    coreSw = (k/2).^2;
    aggrSw = (k/2) * k;
    edgeSw = (k/2) * k;
    
    nodeCount = zeros(coreSw + aggrSw + edgeSw + hostNum);
    nodeName = {};

    sw_number = coreSw + aggrSw + edgeSw;
    
    for i = 1:coreSw
        nodeName{i} = strcat('co-', int2str(i));
    end

    for i = 1+coreSw:coreSw+aggrSw
        nodeName{i} = strcat('ag-', int2str(i-(coreSw)));
    end

    for i = 1+coreSw+aggrSw:coreSw+aggrSw+edgeSw
        nodeName{i} = strcat('ed-', int2str(i-(coreSw+aggrSw)));
    end

    for i = 1+coreSw+aggrSw+edgeSw:coreSw+aggrSw+edgeSw+hostNum
        nodeName{i} = strcat('h-', int2str(i-(coreSw+aggrSw+edgeSw)));
    end

    g = graph(nodeCount, nodeName);
    
    srcNode = {};
    dstNode = {};
    srcInf = [];
    dstInf = [];
    i = 1;
    for j = 1:(k/2):coreSw
        if_aggre = 1;

        for n = j:(j+(k/2))-1
            if_core = 1;

            for m = i:(k/2):aggrSw
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

    for i = 1:(k/2):aggrSw
        if_edge = 1;

        for j = i:(i+(k/2))-1
            if_aggre = (k/2)+1;

            for m = i:(i+(k/2))-1
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

    host_at_pod(1:k) = round(hostNum / k);
    host_at_pod(end) = hostNum - round(hostNum / k)*(k-1);

    host_c = 1;
    pod = 1;
    for i = 1:(k/2):edgeSw
        host_at_sw(1:(k/2)) = round(host_at_pod(pod) / (k/2));
        host_at_sw(end) = host_at_pod(pod) - round(host_at_pod(pod) / (k/2))*(k/2-1);

        m = 1;
        for j = i:(i+(k/2))-1
            if_edge = (k/2)+1;

            for n = host_c:(host_c+host_at_sw(m))-1            
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

            host_c = host_c + host_at_sw(m);
            m = m + 1;
        end

        pod = pod + 1;
    end

    x(1:coreSw) = 1:floor(hostNum/coreSw):floor(hostNum/coreSw)*coreSw;
    x(1+coreSw:coreSw+aggrSw) = 1:floor(hostNum/aggrSw):floor(hostNum/aggrSw)*aggrSw;
    x(1+coreSw+aggrSw:coreSw+aggrSw+edgeSw) = 1:floor(hostNum/edgeSw):floor(hostNum/edgeSw)*edgeSw;
    x(1+coreSw+aggrSw+edgeSw:coreSw+aggrSw+edgeSw+hostNum) = 1:hostNum;

    y(1:coreSw) = 3;
    y(1+coreSw:coreSw+aggrSw) = 2;
    y(1+coreSw+aggrSw:coreSw+aggrSw+edgeSw) = 1;
    y(1+coreSw+aggrSw+edgeSw:coreSw+aggrSw+edgeSw+hostNum) = 0;

    topo = plot(g, 'XData', x, 'YData', y);
end