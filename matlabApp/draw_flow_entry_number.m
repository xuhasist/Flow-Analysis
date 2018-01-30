function draw_flow_entry_number(k, sw_struct, sw_number)
    % change 01:32 to 01:33
    DateStrings = {'2009-12-18 00:26', '2009-12-18 00:48'; '2009-12-18 00:48', '2009-12-18 01:10'; '2009-12-18 01:10', '2009-12-18 01:33'};
    t = datetime(DateStrings,'InputFormat','yyyy-MM-dd HH:mm');

    start_time = [];
    end_time = [];
    slot_num = [];

    for i = 1:length(t)
       start_time(i) = t(i,1).Hour*3600 + t(i,1).Minute*60;
       end_time(i) = t(i,2).Hour*3600 + t(i,2).Minute*60;
       slot_num(i) = (end_time(i) - start_time(i)) / 60;
    end

    all_slot = slot_num(1) + slot_num(2) + slot_num(3);
    final_mean_size = zeros(1, all_slot);
    final_sw_size = zeros(1, all_slot);

    for sw = 1:sw_number
        if isempty(sw_struct(sw).entry)
            continue
        else
            flow_loc = [];
            for i = 1:length(sw_struct(sw).entry)
                flow_time_string = {sw_struct(sw).entry(i).start_time, sw_struct(sw).entry(i).end_time};
                flow_time = datetime(flow_time_string,'Format','yyyy-MM-dd HH:mm:ss.SSS');

                flow_start_time = flow_time(1).Hour*3600 + flow_time(1).Minute*60 + flow_time(1).Second;
                flow_end_time = flow_time(2).Hour*3600 + flow_time(2).Minute*60 + flow_time(2).Second;

                sloc = floor((flow_start_time - start_time(1)) / 60) + 1;
                eloc = floor((flow_end_time - start_time(1)) / 60) + 1;

                flow_loc = [flow_loc, (sloc:eloc)];

                final_mean_size(sloc:eloc) = final_mean_size(sloc:eloc) + 1;
            end
            final_sw_size(unique(flow_loc)) = final_sw_size(unique(flow_loc)) + 1;
        end
    end

    final_mean_size = final_mean_size./final_sw_size;
    final_mean_size = round(final_mean_size);

    formatOut = 'HH:MM';
    begin = 1;
    max_size = max(final_mean_size);
    %max_size = 175;
    for i = 1:length(t)
        x = arrayfun(@(x) x+0.5, (1:slot_num(i)));
        y = final_mean_size(begin:begin+slot_num(i)-1);
        begin = begin + slot_num(i);

        b = bar(x, y);

        %title(['Fat Tree, k = ', int2str(k), 10, 'Time Range: ', datestr(t(i,1),formatOut), ' ~ ', datestr(t(i,2),formatOut), 10])
        title(['AS Number = ', int2str(k), 10, 'Time Range: ', datestr(t(i,1),formatOut), ' ~ ', datestr(t(i,2),formatOut), 10])

        set(gca, 'ylim', [0 max_size])
        set(gca, 'FontSize', 12)
        set(gcf, 'PaperUnits', 'inches')
        set(gcf, 'PaperPosition', [0 0 10 6])

        label = cellstr(string(y));
        label(cellfun(@(x) isequal(x, '0'), label)) = {''};

        text(x, y, label, 'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom')

        xlabel('Time (Minutes)')
        ylabel('Average Flow Rule Numbers')

        print(int2str(i), '-dpng')
    end
end