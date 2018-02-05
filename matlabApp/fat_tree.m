numCore=4;
numAgg=8;
numEdge=8;
numHost=16;

nodeCount = zeros(numCore + numAgg + numEdge + numHost);
nodeName = {};

% name node int2str:change integer to char 
for i = 1:numCore
    nodeName{i} = strcat('core-', int2str(i));
end

for i = 1+numCore:numCore+numAgg
    nodeName{i} = strcat('agg-', int2str(i-(numCore)));
end

for i = 1+numCore+numAgg:numCore+numAgg+numEdge
    nodeName{i} = strcat('edge-', int2str(i-(numCore+numAgg)));
end

for i = 1+numCore+numAgg+numEdge:numCore+numAgg+numEdge+numHost
    nodeName{i} = strcat('host-', int2str(i-(numCore+numAgg-numEdge)));
end

 %g = graph(nodeCount, nodeName);
 g = graph;
 
  i = 1;
  k = 4;
    for j = 1:(k/2):numCore % control core switch

        for n = j:(j+(k/2))-1 % control core switch

            for m = i:(k/2):numAgg % control aggre switch
                g = addedge(g, strcat('core-', int2str(n)), strcat('agg-', int2str(m)));

            end
        end
        i = i + 1 ;    
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
    
    g = reordernodes(g, nodeName(1:numCore+numAgg));
    
    topo = plot(g);