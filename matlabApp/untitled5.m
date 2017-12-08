clearvars
clearvars -global

[col1, col2, col3] = textread('Inet.txt');

nodeCount = zeros(col1(1));

for i = 1:col1(1)
    nodeName{i} = strcat(int2str(i));
end

g = graph(nodeCount, nodeName);

for i = 2+col1(1):length(col1)
    g = addedge(g, nodeName{col1(i)+1}, nodeName{col2(i)+1}, col3(i));
end

topo = plot(g);

