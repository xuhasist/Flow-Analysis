function [flowEntry, flowSrcIp, flowDstIp]  = setFlowEntry(prefixLength, flowEntry, flowTraceTable, i)
    sip = strsplit(flowTraceTable{i, 'SrcIp'}{1}, '.');
    sip = cellfun(@(x) str2num(x), sip);
    sip = dec2bin(sip, 8);
    sip = sip';
    
    dip = strsplit(flowTraceTable{i, 'DstIp'}{1}, '.');
    dip = cellfun(@(x) str2num(x), dip);
    dip = dec2bin(dip, 8);
    dip = dip';
    
    flowSrcIp = sip(1:32);
    flowDstIp = dip(1:32);
    
    %sip(prefixLength + 1:end) = '0';
    %dip(prefixLength + 1:end) = '0';
    
    flowEntry.srcIp = sip(1:prefixLength);
    flowEntry.dstIp = dip(1:prefixLength);
    
    flowEntry.srcPort = 0;
    flowEntry.dstPort = 0;
    
    %{
    if prefixLength == 32
        flowEntry.srcPort = flowTraceTable{i, 'SrcPort'};
        flowEntry.dstPort = flowTraceTable{i, 'DstPort'};
    else
        flowEntry.srcPort = 0;
        flowEntry.dstPort = 0;
    end
    %}
end