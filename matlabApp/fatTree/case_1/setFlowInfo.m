function [srcNodeName, dstNodeName, flowStartStrtime, flowEndStrtime, flowRate, flowTraceTable, flowEntry] = ...
    setFlowInfo(flowStartDatetime, flowEndDatetime, linkBwdUnit, hostIpTable, flowTraceTable, i)
            
    rows = strcmp(hostIpTable.IP, flowTraceTable{i,'SrcIp'}{1});
    srcNodeName = hostIpTable{rows, {'Host'}}{1};
    
    rows = strcmp(hostIpTable.IP, flowTraceTable{i,'DstIp'}{1});
    dstNodeName = hostIpTable{rows, {'Host'}}{1};
    
    flowStartStrtime = datestr(flowStartDatetime, 'yyyy-mm-dd HH:MM:ss.FFF');
    flowEndStrtime = datestr(flowEndDatetime, 'yyyy-mm-dd HH:MM:ss.FFF');
    
    flowEntryEndStrtime = datestr(flowEndDatetime + seconds(60), 'yyyy-mm-dd HH:MM:ss.FFF');
    
    % flow demand
    %duration = seconds(flowEndDatetime - flowStartDatetime);
    %flowRate = flowTraceTable{i, 'Bytes'} / duration;
    
    % saturation
    flowRate = (10 * linkBwdUnit) / 8; % ?B/s

    flowTraceTable.Rate_bps(i) = flowRate * 8;

    flowEntry = struct();
    flowEntry.startTime = flowStartStrtime;
    flowEntry.endTime = flowEntryEndStrtime;
    flowEntry.protocol = flowTraceTable{i, 'Protocol'}{1};
end