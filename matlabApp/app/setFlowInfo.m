function [src_name, dst_name, flow_start_datetime, flow_end_datetime, flow_start_strtime, flow_end_strtime, flow, flow_table, flow_entry] = setFlowInfo(link_bwd_unit, host_ip, flow_table, i)
    rows = strcmp(host_ip.IP, flow_table{i,'srcip'}{1});
    src_name = host_ip{rows, {'Host'}}{1};
    
    rows = strcmp(host_ip.IP, flow_table{i,'dstip'}{1});
    dst_name = host_ip{rows, {'Host'}}{1};
    
    flow_start_datetime = datetime(flow_table{i, 'start_date_time'}{1}, 'Format', 'yyyy-MM-dd HH:mm:ss.SSS');
    flow_end_datetime = datetime(flow_table{i, 'end_date_time'}{1}, 'Format', 'yyyy-MM-dd HH:mm:ss.SSS');
    
    flow_start_strtime = datestr(flow_start_datetime, 'yyyy-mm-dd HH:MM:ss.FFF');
    flow_end_strtime = datestr(flow_end_datetime, 'yyyy-mm-dd HH:MM:ss.FFF');
    
    flow_entry_end_strtime = datestr(flow_end_datetime + seconds(60), 'yyyy-mm-dd HH:MM:ss.FFF');
    
    % flow demand
    duration = seconds(flow_end_datetime - flow_start_datetime);
    rate = flow_table{i, 'bytes'} / duration;
    
    % saturation
    %rate = (10 * link_bwd_unit) / 8; % ?B/s

    flow.rate = rate;
    flow_table.rate_bps(i) = rate * 8;

    flow_entry = struct();
    flow_entry.start_time = flow_start_strtime;
    flow_entry.end_time = flow_entry_end_strtime;
    %flow_entry.end_time = flow_end_strtime;
    flow_entry.protocol = flow_table{i, 'protocol'}{1};
end