function [link_struct, final_network_throuput] = draw_link_througuput(g, link_bwd_unit, link_struct, k, flow_final_path, flow_table)
    %[link_struct, final_network_throuput] = byFlowDemand(g, link_bwd_unit, link_struct, flow_final_path, flow_table);
    [link_struct, final_network_throuput] = byFlowSaturation(g, link_bwd_unit, link_struct, flow_final_path, flow_table);
    
    begin_time = datetime('2009-12-18 00:26', 'Format', 'yyyy-MM-dd HH:mm:ss');
    end_time = datetime('2009-12-18 01:33', 'Format', 'yyyy-MM-dd HH:mm:ss');

    x = (1:length(final_network_throuput));
    x = x + 0.5;
    final_network_throuput = final_network_throuput / link_bwd_unit;

    b = bar(x, final_network_throuput);

    formatOut = 'HH:MM';
    
    title(['Fat Tree, k = ', int2str(k), 10, 'Time Range: ', datestr(begin_time,formatOut), ' ~ ', datestr(end_time,formatOut), 10])
    %title(['AS Number = ', int2str(k), 10, 'Time Range: ', datestr(begin_time,formatOut), ' ~ ', datestr(end_time,formatOut), 10])
    
    %max_size = max(final_network_throuput);
    max_size = 42.0324;
        
    set(gca, 'ylim', [0 max_size])
    set(gca, 'FontSize', 12)
    set(gcf, 'PaperUnits', 'inches')
    set(gcf, 'PaperPosition', [0 0 10 6])

    xlabel('Time (Seconds)')
    ylabel('Network Throuput (Kbps)')
    
    %print('throughput_flowDemand', '-dpng')
    print('throughput_flowSaturation', '-dpng')
end

function [link_struct, final_network_throuput] = byFlowDemand(g, link_bwd_unit, link_struct, flow_final_path, flow_table)
    for i = 1:length(link_struct)
        if isempty(link_struct(i).entry)
            continue
        else
            rows = cellfun(@strcmp, {link_struct(i).entry.start_time}, {link_struct(i).entry.end_time});
            link_struct(i).entry(rows) = [];

            rows = [link_struct(i).entry.load]*8 > 10*link_bwd_unit;

            x = num2cell((10*link_bwd_unit)./ ([link_struct(i).entry(rows).load]*8));
            [link_struct(i).entry(rows).limit] = deal(x{:});

            x = num2cell(datetime({link_struct(i).entry.start_time}', 'Format', 'yyyy-MM-dd HH:mm:ss.SSS'));
            [link_struct(i).entry.start_time] = deal(x{:});

            x = num2cell(datetime({link_struct(i).entry.end_time}', 'Format', 'yyyy-MM-dd HH:mm:ss.SSS'));
            [link_struct(i).entry.end_time] = deal(x{:});
        end
    end

    flow_table_start_date_time = datetime(flow_table.start_date_time, 'Format', 'yyyy-MM-dd HH:mm:ss.SSS');
    flow_table_end_date_time = datetime(flow_table.end_date_time, 'Format', 'yyyy-MM-dd HH:mm:ss.SSS');

    final_network_throuput = [];

    begin_time = datetime('2009-12-18 00:26', 'Format', 'yyyy-MM-dd HH:mm:ss');
    end_time = datetime('2009-12-18 01:33', 'Format', 'yyyy-MM-dd HH:mm:ss');

    preEnd_tmp = ones(1, length(link_struct));
    while begin_time ~= end_time
        begin_time

        preEnd = preEnd_tmp;
        link_entry_cluster = {};

        rows = ((flow_table_start_date_time >= begin_time) & (flow_table_start_date_time < begin_time + seconds(1))) | ((flow_table_end_date_time >= begin_time) & (flow_table_end_date_time <= begin_time + seconds(1)));

        if find(rows==1)
            flow_index = find(rows==1);
            rate_array = flow_table{flow_index, {'rate_bps'}};

            for i = 1:length(flow_index)
                path = flow_final_path{flow_index(i)};
                path(diff(path)==0) = [];

                edge = findedge(g, path, circshift(path, -1));

                for j = 1:length(edge)-1
                    if isempty(link_entry_cluster) || length(link_entry_cluster) < edge(j) || isempty(link_entry_cluster{edge(j)}) 
                        rows = (([link_struct(edge(j)).entry(preEnd(edge(j)):end).start_time] >= begin_time) & ([link_struct(edge(j)).entry(preEnd(edge(j)):end).start_time] < begin_time + seconds(1))) | (([link_struct(edge(j)).entry(preEnd(edge(j)):end).end_time] >= begin_time) & ([link_struct(edge(j)).entry(preEnd(edge(j)):end).end_time] <= begin_time + seconds(1)));
                        link_entry_cluster{edge(j)} = rows;
                    else
                        rows = link_entry_cluster{edge(j)};
                    end

                    rows_index = find(rows==1);
                    rows_index = rows_index + preEnd(edge(j)) - 1;

                    s_time = [link_struct(edge(j)).entry(rows_index).start_time];
                    e_time = [link_struct(edge(j)).entry(rows_index).end_time];
                    rate_array_tmp = {link_struct(edge(j)).entry(rows_index).limit};

                    preEnd_tmp(edge(j)) = rows_index(end);

                    rows = s_time < begin_time;
                    s_time(rows) = begin_time;

                    rows = e_time > begin_time + seconds(1);
                    e_time(rows) = begin_time + seconds(1);

                    ration = seconds(e_time - s_time);
                    ration = ration / sum(ration);

                    rows = cellfun(@isempty,rate_array_tmp);

                    x = num2cell(repmat(rate_array(i), 1, length(find(rows==1))));
                    [rate_array_tmp{rows}] = deal(x{:});

                    x = num2cell(rate_array(i) * [rate_array_tmp{~rows}]);
                    [rate_array_tmp{~rows}] = deal(x{:});

                    rate_array_tmp = cell2mat(rate_array_tmp);
                    rate_array_tmp = rate_array_tmp.* ration;
                    tmp_rate = sum(rate_array_tmp);

                    if tmp_rate < rate_array(i)
                        rate_array(i) = tmp_rate;
                    end
                end
            end

            final_network_throuput = [final_network_throuput, sum(rate_array)];
        else
            final_network_throuput = [final_network_throuput, 0];
        end

        begin_time = begin_time + seconds(1);
    end
end

function [link_struct, final_network_throuput] = byFlowSaturation(g, link_bwd_unit, link_struct, flow_final_path, flow_table)
    for i = 1:length(link_struct)
        if isempty(link_struct(i).entry)
            continue
        else
            rows = cellfun(@strcmp, {link_struct(i).entry.start_time}, {link_struct(i).entry.end_time});
            link_struct(i).entry(rows) = [];

            x = num2cell((10*link_bwd_unit)./ [link_struct(i).entry.flowNum]);
            [link_struct(i).entry.limit] = deal(x{:});

            x = num2cell(datetime({link_struct(i).entry.start_time}', 'Format', 'yyyy-MM-dd HH:mm:ss.SSS'));
            [link_struct(i).entry.start_time] = deal(x{:});

            x = num2cell(datetime({link_struct(i).entry.end_time}', 'Format', 'yyyy-MM-dd HH:mm:ss.SSS'));
            [link_struct(i).entry.end_time] = deal(x{:});
        end
    end

    flow_table_start_date_time = datetime(flow_table.start_date_time, 'Format', 'yyyy-MM-dd HH:mm:ss.SSS');
    flow_table_end_date_time = datetime(flow_table.end_date_time, 'Format', 'yyyy-MM-dd HH:mm:ss.SSS');

    final_network_throuput = [];

    begin_time = datetime('2009-12-18 00:26', 'Format', 'yyyy-MM-dd HH:mm:ss');
    end_time = datetime('2009-12-18 01:33', 'Format', 'yyyy-MM-dd HH:mm:ss');

    preEnd_tmp = ones(1, length(link_struct));
    while begin_time ~= end_time
        begin_time

        preEnd = preEnd_tmp;
        link_entry_cluster = {};
        
        rows = ((flow_table_start_date_time >= begin_time) & (flow_table_start_date_time < begin_time + seconds(1))) | ((flow_table_end_date_time >= begin_time) & (flow_table_end_date_time <= begin_time + seconds(1)));

        if find(rows==1)
            flow_index = find(rows==1);
            rate_array = repmat(10*link_bwd_unit, 1, length(flow_index));

            for i = 1:length(flow_index)
                path = flow_final_path{flow_index(i)};
                path(diff(path)==0) = [];

                edge = findedge(g, path, circshift(path, -1));

                for j = 1:length(edge)-1
                    if isempty(link_entry_cluster) || length(link_entry_cluster) < edge(j) || isempty(link_entry_cluster{edge(j)}) 
                        rows = (([link_struct(edge(j)).entry(preEnd(edge(j)):end).start_time] >= begin_time) & ([link_struct(edge(j)).entry(preEnd(edge(j)):end).start_time] < begin_time + seconds(1))) | (([link_struct(edge(j)).entry(preEnd(edge(j)):end).end_time] >= begin_time) & ([link_struct(edge(j)).entry(preEnd(edge(j)):end).end_time] <= begin_time + seconds(1)));
                        link_entry_cluster{edge(j)} = rows;
                    else
                        rows = link_entry_cluster{edge(j)};
                    end

                    rows_index = find(rows==1);
                    rows_index = rows_index + preEnd(edge(j)) - 1;

                    s_time = [link_struct(edge(j)).entry(rows_index).start_time];
                    e_time = [link_struct(edge(j)).entry(rows_index).end_time];
                    rate_array_tmp = [link_struct(edge(j)).entry(rows_index).limit];

                    preEnd_tmp(edge(j)) = rows_index(end);

                    rows = s_time < begin_time;
                    s_time(rows) = begin_time;

                    rows = e_time > begin_time + seconds(1);
                    e_time(rows) = begin_time + seconds(1);

                    ration = seconds(e_time - s_time);
                    ration = ration / sum(ration);

                    rate_array_tmp = rate_array_tmp.* ration;
                    tmp_rate = sum(rate_array_tmp);

                    if tmp_rate < rate_array(i)
                        rate_array(i) = tmp_rate;
                    end
                end
            end

            final_network_throuput = [final_network_throuput, sum(rate_array)];
        else
            final_network_throuput = [final_network_throuput, 0];
        end

        begin_time = begin_time + seconds(1);
    end
end