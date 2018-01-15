clearvars
t1 = datetime('now');

host_x = 15;
host_sd = 3;

% fat tree
%k = 4;
%[sw_number, srcNode, dstNode, srcInf, dstInf, g, edge_subnet, host_at_sw, hostNum, IP] = ...
%    createFatTreeTopo_mod(k, host_x, host_sd);

% AS_topo
as_edge_sw_num = 5;
[sw_number, srcNode, dstNode, srcInf, dstInf, g, asNum, nodeT, edge_subnet, host_at_sw, hostNum, IP] = ...
    createAsTopo_mod(as_edge_sw_num, host_x, host_sd);

flowNum = 2000;
[link_if, host_ip, sw_struct, link, link_struct, pkt_table] = ...
    setVariables_pkt(sw_number, srcNode, dstNode, srcInf, dstInf, g, hostNum, IP, flowNum);

sw_vector = distances(g, 'Method', 'unweighted');
sw_vector = sw_vector(1:sw_number, 1:sw_number);

% for as topo
rows = strcmp(nodeT.Type, 'RT_NODE');
sw_vector(rows, rows) = 0;

link_bwd_unit = 10^3; %10Kbps
pkt_final_path = {};
preLower = [];

hierarchy_table = table();

prefix_length = 16; %bits
prefix_threshold = 16;

has_hierarchy = false;

schedule = timer;
schedule.Period = 3;
schedule.TasksToExecute = inf;
schedule.ExecutionMode = 'fixedRate';
schedule.TimerFcn = 'updatePrefixLength = true;';
schedule.StartDelay = 10;
start(schedule)
updatePrefixLength = false;

pkt_table.group = repmat({[]}, size(pkt_table, 1), 1);
pkt_table = simularityClustering_pkt(prefix_length, host_ip, link_if, pkt_table, 1);

t2 = datetime('now');
disp(t2 - t1)

for i = 1:size(pkt_table, 1)
    
end

stop(schedule)

t2 = datetime('now');
disp(t2 - t1)