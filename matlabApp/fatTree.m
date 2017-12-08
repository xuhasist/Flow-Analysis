clearvars

x = zeros(36);
nodeName = {};

% node name
for i = 1:4
    nodeName{i} = int2str(1000 + i);
end

for i = 5:12
    nodeName{i} = int2str(2000 + (i-4));
end

for i = 13:20
    nodeName{i} = int2str(3000 + (i-12));
end

for i = 21:36
    nodeName{i} = strcat('h', int2str(i-20));
end

g = graph(x, nodeName);

% add weighted edge
%randi([5, 20])
for i = 1:4
    for j = (floor(i/3)+5):2:12
        g = addedge(g, nodeName{i}, nodeName{j}, 100);
    end
end

for i = 5:12
    j = i + mod(i,2) + 7;
    g = addedge(g, nodeName{i}, nodeName{j}, 10);
    g = addedge(g, nodeName{i}, nodeName{j+1}, 10);
end

j = 13;
for i = 21:2:36
    g = addedge(g, nodeName{i}, nodeName{j}, 1);
    g = addedge(g, nodeName{i+1}, nodeName{j}, 1);
    j = j + 1;
end

% set coordinates
x=[];
y=[];

x(1:4) = 7:5:23;
x(5:12) = 1:4:29;
x(13:20) = 1:4:29;
x(21:36) = 0:2:30;
y(1:4) = 3;
y(5:12) = 1;
y(13:20) = 0;
y(21:36) = -1;

topo = plot(g, 'XData', x, 'YData', y, 'EdgeLabel', g.Edges.Weight);

% generate elephant flow randomly
flow = [];
for i = 1:1
    f.src_name = strcat('h', int2str(randi([1, 16])));
    f.dst_name = strcat('h', int2str(randi([1, 16])));
    while strcmp(f.src_name, f.dst_name)
        f.dst_name = strcat('h', int2str(randi([1, 16])));
    end
    f.rate = randi([1, 10]);
    f.path = shortestpath(g, f.src_name, f.dst_name, 'Method', 'unweighted');
    
    flow = [flow, f];
end

%{
link = [];
link.weight = g.Edges.Weight;
link.load = randi([1, 15], 48, 1);
%}

link = g.Edges;
link.Load = zeros(length(link.Weight),1);

%[resultPath, link] = firstFitFlowScheduling_mod(g, flow, link);
%link = modifiedLink;
shortestPaths = dijkstra(g, 21, 30);