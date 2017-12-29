function flow_entry = setFlowEntryForPerflow(flow_entry, flow_table, i)
    flow_entry.src_ip = flow_table{i, 'srcip'}{1};
    flow_entry.dst_ip = flow_table{i,'dstip'}{1};
    flow_entry.src_port = flow_table{i, 'srcport'};
    flow_entry.dst_port = flow_table{i, 'dstport'};
end