function flow_entry = setFlowEntryForCluster(flow_entry, flow_table, i, group)
    sip = strsplit(flow_table{i, 'srcip'}{1}, '.');
    dip = strsplit(flow_table{i, 'dstip'}{1}, '.');

    if group == 1
        flow_entry.src_ip = [sip{1}, '.0.0.0'];
        flow_entry.dst_ip = [dip{1}, '.0.0.0'];
    elseif group == 2
        flow_entry.src_ip = [sip{1}, '.', sip{2}, '.0.0'];
        flow_entry.dst_ip = [dip{1}, '.', dip{2}, '.0.0'];
    elseif group == 3
        flow_entry.src_ip = [sip{1}, '.', sip{2}, '.', sip{3}, '.0'];
        flow_entry.dst_ip = [dip{1}, '.', dip{2}, '.', dip{3}, '.0'];
    else
        flow_entry.src_ip = flow_table{i, 'srcip'}{1};
        flow_entry.dst_ip = flow_table{i, 'dstip'}{1};
    end
end