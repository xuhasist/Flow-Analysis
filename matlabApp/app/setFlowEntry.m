function [flow_entry, flow_src_ip, flow_dst_ip] = setFlowEntry(prefix_length, flow_entry, flow_table, i)
    sip = strsplit(flow_table{i, 'srcip'}{1}, '.');
    sip = cellfun(@(x) str2num(x), sip);
    sip = dec2bin(sip, 8);
    sip = sip';
    
    dip = strsplit(flow_table{i, 'dstip'}{1}, '.');
    dip = cellfun(@(x) str2num(x), dip);
    dip = dec2bin(dip, 8);
    dip = dip';
    
    flow_src_ip = sip(1:32);
    flow_dst_ip = dip(1:32);
    
    sip(prefix_length + 1:end) = '0';
    dip(prefix_length + 1:end) = '0';
    
    %sip(flow_table.prefix(i) + 1:end) = '0';
    %dip(flow_table.prefix(i) + 1:end) = '0';
    
    %flow_entry.src_ip = [num2str(bin2dec(sip(1:8))), '.', num2str(bin2dec(sip(9:16))), '.', num2str(bin2dec(sip(17:24))), '.', num2str(bin2dec(sip(25:32)))];
    %flow_entry.dst_ip = [num2str(bin2dec(dip(1:8))), '.', num2str(bin2dec(dip(9:16))), '.', num2str(bin2dec(dip(17:24))), '.', num2str(bin2dec(dip(25:32)))];
    
    flow_entry.src_ip = sip(1:prefix_length);
    flow_entry.dst_ip = dip(1:prefix_length);
    
    flow_entry.src_port = 0;
    flow_entry.dst_port = 0;
    
    %{
    if prefix_length == 32
        flow_entry.src_port = flow_table{i, 'srcport'};
        flow_entry.dst_port = flow_table{i, 'dstport'};
    else
        flow_entry.src_port = 0;
        flow_entry.dst_port = 0;
    end
    %}
end