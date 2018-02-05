function sw_struct = removeAllFlowEntry(sw_struct, flow_start_datetime)
    for i = 1:length(sw_struct)
        if isempty(sw_struct(i).entry)
            continue;
        end
        
        rows = datetime({sw_struct(i).entry.end_time}, 'Format', 'yyyy-MM-dd HH:mm:ss.SSS') >= flow_start_datetime;
        
        c = cell(1, length(find(rows)));
        c(1:end) = {datestr(flow_start_datetime - seconds(0.001), 'yyyy-mm-dd HH:MM:ss.FFF')};
        [sw_struct(i).entry(rows).end_time] = deal(c{:});
    end
end