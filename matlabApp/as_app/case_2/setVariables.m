function [swInfTable, swFlowEntryStruct, hostIpTable, linkTable, linkThputStruct, flowTraceTable, flowSequence, swFlowEntryStruct_accumulation] = ...
    setVariables(swNum, srcNode, dstNode, srcInf, dstInf, g, hostNum, IP, flowNum)

    swInfTable = table(srcNode, dstNode, srcInf, dstInf);
    swInfTable.Properties.VariableNames = {'SrcNode', 'DstNode', 'SrcInf', 'DstInf'};
    
    hostIpTable = table(g.Nodes.Name(1+swNum:swNum+hostNum), IP');
    hostIpTable.Properties.VariableNames = {'Host', 'IP'};

    swFlowEntryStruct = struct([]);
    for i = 1:swNum
       swFlowEntryStruct(i).entry = struct([]);
    end

    linkTable = g.Edges;
    %linkTable.Load = zeros(size(linkTable, 1), 1);

    linkThputStruct = struct([]);
    for i = 1:size(linkTable, 1)
        linkThputStruct(i).entry = struct([]);
    end
    
    swFlowEntryStruct_accumulation = struct([]);
    for i = 1:swNum
       swFlowEntryStruct_accumulation(i).entry = struct([]);
    end

    allPktTrace = textread('pktTrace_5min.txt', '%s', 'delimiter', '\n', 'bufsize', 2147483647);
    
    pktTraceNum = length(allPktTrace);
    pickPktTrace = randi(pktTraceNum, 1, flowNum);
    
    start_time = datetime('2009-12-18 00:26:04.398', 'Format', 'yyyy-MM-dd HH:mm:ss.SSS');
    end_time = datetime('2009-12-18 00:31:04.398', 'Format', 'yyyy-MM-dd HH:mm:ss.SSS');
    slot_num = seconds(end_time - start_time);
    
    %allTrace_end_time = datetime('2009-12-18 01:31:18.921', 'Format', 'yyyy-MM-dd HH:mm:ss.SSS');
    
    flowSequence = [];
    flowTraceTable = table();
    
    for i = 1:flowNum
        pktTrace = allPktTrace{pickPktTrace(i)};
        pktTrace = jsondecode(pktTrace);
        
        pktDatetime = datetime({pktTrace.send.time}, 'Format', 'yyyy-MM-dd HH:mm:ss.SSS');
        
        %{
        new_pktDatetime = seconds(seconds(pktDatetime - start_time) * seconds((end_time - seconds(0.001)) - start_time) / seconds(allTrace_end_time - start_time)) + start_time;
        new_pktDatetime = num2cell(new_pktDatetime);
        [pktTrace.send.time] = deal(new_pktDatetime{:});
        
        pktTrace.start_date_time = datestr(pktTrace.send(1).time, 'yyyy-mm-dd HH:MM:ss.FFF');
        pktTrace.end_date_time = datestr(pktTrace.send(end).time, 'yyyy-mm-dd HH:MM:ss.FFF');
        
        pktDatetime = [pktTrace.send.time];
        %}
        loc = floor(seconds(pktDatetime - start_time)) + 1;
        
        flowSequence(i,:) = zeros(slot_num, 1);
        flowSequence(i, loc) = 1;
        
        % case 1: pick src & dst ip randomly
        node = randperm(length(IP), 2);
        srcIp = IP{node(1)};
        dstIp = IP{node(2)};
        
        % case 2: pick src ip from first two thirds of all ip and
        % dst ip from last one third of all ip randomly
        %srcIp = IP{randi(length(IP(1:floor(length(IP)*2/3))), 1)};
        %dstIp = IP{randi(length(IP(floor(length(IP)*2/3)+1:end)), 1)};
        
        srcPort = pktTrace.attr.src_port;
        dstPort = pktTrace.attr.dst_port;
        protocol = pktTrace.attr.protocol;
        
        % flow timeout is 60 seconds
        rows = seconds(pktDatetime - circshift(pktDatetime, 1)) > 60;
        if any(rows)
            s = 1;
            newFlowId = find(rows);
            for j = 1:length(newFlowId)
                e = newFlowId(j) - 1;
                
                %startDatetime = datestr(pktTrace.send(s).time, 'yyyy-mm-dd HH:MM:ss.FFF');
                %endDatetime = datestr(pktTrace.send(e).time, 'yyyy-mm-dd HH:MM:ss.FFF');
                startDatetime = pktTrace.send(s).time;
                endDatetime = pktTrace.send(e).time;
                bytes = sum([pktTrace.send(s:e).size]);
                
                flowTraceTable = [flowTraceTable; {i, startDatetime, endDatetime, srcIp, dstIp, srcPort, dstPort, protocol, bytes}];
                
                s = newFlowId(j);
            end
            
            %startDatetime = datestr(pktTrace.send(s).time, 'yyyy-mm-dd HH:MM:ss.FFF');
            startDatetime = pktTrace.send(s).time;
            endDatetime = pktTrace.end_date_time;
            bytes = sum([pktTrace.send(s:end).size]);

            flowTraceTable = [flowTraceTable; {i, startDatetime, endDatetime, srcIp, dstIp, srcPort, dstPort, protocol, bytes}];

        else
            startDatetime = pktTrace.start_date_time;
            endDatetime = pktTrace.end_date_time;

            bytes = pktTrace.attr.transferred_bytes;

            flowTraceTable = [flowTraceTable; {i, startDatetime, endDatetime, srcIp, dstIp, srcPort, dstPort, protocol, bytes}];
        end
    end
    
    flowTraceTable.Properties.VariableNames = {'Index', 'StartDatetime', 'EndDatetime', 'SrcIp', 'DstIp', 'SrcPort', 'DstPort', 'Protocol', 'Bytes'};
    flowTraceTable = sortrows(flowTraceTable, 'StartDatetime');
    
    clearvars allPktTrace
end