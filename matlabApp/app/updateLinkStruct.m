function [link_struct, preLower] = updateLinkStruct(final_path, g, link_struct, flow_start_datetime, flow_end_datetime, flow_end_strtime, preLower, flow_entry, rate)
    for j = 1:length(final_path)-1
        edge = findedge(g, final_path(j), final_path(j+1));

        k_ = length(link_struct(edge).entry);

        lower = -1;
        upper = -1;

        if isempty(link_struct(edge).entry)
        else            
            rows = (flow_start_datetime >= datetime({link_struct(edge).entry(preLower(edge):end).start_time}', 'Format', 'yyyy-MM-dd HH:mm:ss.SSS')) & (flow_start_datetime < datetime({link_struct(edge).entry(preLower(edge):end).end_time}', 'Format', 'yyyy-MM-dd HH:mm:ss.SSS'));
            if find(rows == 1)
                lower = (find(rows == 1) + preLower(edge) - 1);
            end

            rows = (flow_end_datetime >= datetime({link_struct(edge).entry(preLower(edge):end).start_time}', 'Format', 'yyyy-MM-dd HH:mm:ss.SSS')) & (flow_end_datetime < datetime({link_struct(edge).entry(preLower(edge):end).end_time}', 'Format', 'yyyy-MM-dd HH:mm:ss.SSS'));
            if find(rows == 1)
                upper = (find(rows == 1) + preLower(edge) - 1);
            end
        end

        if lower == -1 && upper == -1
            link_struct(edge).entry(k_+1).start_time = flow_entry.start_time;
            link_struct(edge).entry(k_+1).end_time = flow_end_strtime;
            link_struct(edge).entry(k_+1).load = rate;
            link_struct(edge).entry(k_+1).flowNum = 1;
        elseif lower == upper && upper ~= -1
            link_struct(edge).entry(k_+1).start_time = flow_entry.start_time;
            link_struct(edge).entry(k_+1).end_time = flow_end_strtime;
            link_struct(edge).entry(k_+1).load = rate +  link_struct(edge).entry(lower).load;
            link_struct(edge).entry(k_+1).flowNum = 1 + link_struct(edge).entry(lower).flowNum;

            link_struct(edge).entry(k_+2).start_time = flow_end_strtime;
            link_struct(edge).entry(k_+2).end_time = link_struct(edge).entry(lower).end_time;
            link_struct(edge).entry(k_+2).load = link_struct(edge).entry(lower).load;
            link_struct(edge).entry(k_+2).flowNum = link_struct(edge).entry(lower).flowNum;

            if strcmp(link_struct(edge).entry(lower).start_time, flow_entry.start_time)
                link_struct(edge).entry(lower) = [];
            else
                link_struct(edge).entry(lower).end_time = flow_entry.start_time;
            end
        elseif lower == k_ && upper == -1
            link_struct(edge).entry(k_+1).start_time = link_struct(edge).entry(lower).end_time;
            link_struct(edge).entry(k_+1).end_time = flow_end_strtime;
            link_struct(edge).entry(k_+1).load = rate;
            link_struct(edge).entry(k_+1).flowNum = 1;

            link_struct(edge).entry(k_+2).start_time = flow_entry.start_time;
            link_struct(edge).entry(k_+2).end_time = link_struct(edge).entry(lower).end_time;
            link_struct(edge).entry(k_+2).load = rate +  link_struct(edge).entry(lower).load;
            link_struct(edge).entry(k_+2).flowNum = 1 + link_struct(edge).entry(lower).flowNum;

            if strcmp(link_struct(edge).entry(lower).start_time, flow_entry.start_time)
                link_struct(edge).entry(lower) = [];
            else
                link_struct(edge).entry(lower).end_time = flow_entry.start_time;
            end
        elseif lower < upper || upper == -1
            if upper == -1
                for n = lower+1:k_
                    link_struct(edge).entry(n).load = rate + link_struct(edge).entry(n).load;
                    link_struct(edge).entry(n).flowNum = 1 + link_struct(edge).entry(n).flowNum;
                end

                link_struct(edge).entry(k_+1).start_time = link_struct(edge).entry(k_).end_time;
                link_struct(edge).entry(k_+1).end_time = flow_end_strtime;
                link_struct(edge).entry(k_+1).load = rate;
                link_struct(edge).entry(k_+1).flowNum = 1;
            else
                for n = lower+1:upper-1
                    link_struct(edge).entry(n).load = rate + link_struct(edge).entry(n).load;
                    link_struct(edge).entry(n).flowNum = 1 + link_struct(edge).entry(n).flowNum;
                end

                link_struct(edge).entry(k_+1).start_time = flow_end_strtime;
                link_struct(edge).entry(k_+1).end_time = link_struct(edge).entry(upper).end_time;
                link_struct(edge).entry(k_+1).load = link_struct(edge).entry(upper).load;
                link_struct(edge).entry(k_+1).flowNum = link_struct(edge).entry(upper).flowNum;

                link_struct(edge).entry(upper).end_time = flow_end_strtime;
                link_struct(edge).entry(upper).load = rate + link_struct(edge).entry(upper).load;
                link_struct(edge).entry(upper).flowNum = 1 + link_struct(edge).entry(upper).flowNum;
            end

            link_struct(edge).entry(k_+2).start_time = flow_entry.start_time;
            link_struct(edge).entry(k_+2).end_time = link_struct(edge).entry(lower).end_time;
            link_struct(edge).entry(k_+2).load = rate +  link_struct(edge).entry(lower).load;
            link_struct(edge).entry(k_+2).flowNum = 1 +  link_struct(edge).entry(lower).flowNum;

            if strcmp(link_struct(edge).entry(lower).start_time, flow_entry.start_time)
                link_struct(edge).entry(lower) = [];
            else
                link_struct(edge).entry(lower).end_time = flow_entry.start_time;
            end
        end

        [tmp, ind] = sortrows({link_struct(edge).entry.start_time}');
        link_struct(edge).entry = link_struct(edge).entry(ind);

        if lower == -1
            preLower(edge) = length(link_struct(edge).entry);
        else
            preLower(edge) = lower;
        end
    end
end