function [link_if, host_ip, sw_struct, link, link_struct, pkt_table] = setVariables_pkt(sw_number, srcNode, dstNode, srcInf, dstInf, g, hostNum, IP, flowNum)
    link_if = table(srcNode, dstNode, srcInf, dstInf);
    link_if.Properties.VariableNames = {'Src_Node', 'Dst_Node', 'Src_Inf', 'Dst_Inf'};
    
    host_ip = table(g.Nodes.Name(1+sw_number:sw_number+hostNum), IP');
    host_ip.Properties.VariableNames = {'Host', 'IP'};

    sw_struct = struct([]);
    for i = 1:sw_number
       sw_struct(i).entry = struct([]);
    end

    link = g.Edges;
    link.Load = zeros(length(link.Weight),1);

    link_struct = struct([]);
    for i = 1:size(link, 1)
        link_struct(i).entry = struct([]);
    end

    all_pkt_trace = textread('pktTrace.txt', '%s', 'delimiter', '\n', 'bufsize', 2147483647);
    
    packTraceNum = length(all_pkt_trace);
    pick_packTrace = randi(packTraceNum, 1, flowNum);
    
    pkt_table = table();
    for i = 1:flowNum
        pkt_trace = all_pkt_trace{pick_packTrace(i)};
        pkt_trace = jsondecode(pkt_trace);
        
        % case 1: pick src & dst ip randomly
        %node = randperm(length(IP), 2);
        %srcip = IP{node(1)};
        %dstip = IP{node(2)};
        
        % case 2: pick src ip from first third of all ip and dst ip from
        % last two thirds of all ip randomly
        srcip = IP{randi(length(IP(1:floor(length(IP)/3))), 1)};
        dstip = IP{randi(length(IP(floor(length(IP)/3)+1:end)), 1)};
        
        srcport = pkt_trace.attr.src_port;
        dstport = pkt_trace.attr.dst_port;
        protocol = pkt_trace.attr.protocol;
        bytes = pkt_trace.attr.transferred_bytes;
        
        srcip = repmat({srcip}, length(pkt_trace.send), 1);
        dstip = repmat({dstip}, length(pkt_trace.send), 1);
        srcport = repmat({srcport}, length(pkt_trace.send), 1);
        dstport = repmat({dstport}, length(pkt_trace.send), 1);
        protocol = repmat({protocol}, length(pkt_trace.send), 1);
        
        pktTime = {pkt_trace.send.time};
        pktBytes = {pkt_trace.send.size};
        
        pkt_table = [pkt_table; [pktTime', srcip, dstip, srcport, dstport, protocol, pktBytes']];
    end
    
    pkt_table.Properties.VariableNames = {'start_date_time', 'srcip', 'dstip', 'srcport', 'dstport', 'protocol', 'bytes'};
    pkt_table = sortrows(pkt_table, 'start_date_time');
    
    clearvars all_pkt_trace
end